# Kafka Event Contracts

## Обзор

Система использует событийно-ориентированную архитектуру (Event-Driven Design).
Все сообщения передаются в формате JSON через Apache Kafka.

---

## Топики

### 1. `events.analysis.start_static`

| Параметр | Значение |
|----------|----------|
| **Producer** | Analysis API |
| **Consumer** | Worker Static Analyzer |
| **Триггер** | Пользователь загрузил .c файл через POST /api/v1/analysis/upload |

**Payload:**

```json
{
  "task_id": "550e8400-e29b-41d4-a716-446655440000",
  "project_id": "11111111-2222-3333-4444-555555555555",
  "file_s3_path": "source-codes/project-uuid/file-uuid.c"
}
```

| Поле | Тип | Описание |
|------|-----|----------|
| `task_id` | UUID (string) | Уникальный ID задачи анализа |
| `project_id` | UUID (string) | ID проекта, к которому привязан файл (нужен для ClickHouse) |
| `file_s3_path` | string | Путь к файлу в MinIO (bucket/key) |

---

### 2. `events.analysis.static_completed`

| Параметр | Значение |
|----------|----------|
| **Producer** | Worker Static Analyzer |
| **Consumer** | Analysis API |
| **Триггер** | Воркер завершил статический анализ |

**Payload (успех):**

```json
{
  "task_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "success",
  "artifact_s3_path": "analysis-artifacts/550e8400-e29b-41d4-a716-446655440000/static-out.json"
}
```

**Payload (ошибка):**

```json
{
  "task_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "error",
  "error": "failed to parse C source file"
}
```

| Поле | Тип | Описание |
|------|-----|----------|
| `task_id` | UUID (string) | ID задачи |
| `status` | string | `"success"` или `"error"` |
| `artifact_s3_path` | string (optional) | Путь к артефакту в MinIO |
| `error` | string (optional) | Описание ошибки |

---

### 3. `events.analysis.start_cache`

| Параметр | Значение |
|----------|----------|
| **Producer** | Analysis API |
| **Consumer** | Worker Cache Interpreter |
| **Триггер** | Analysis API получил `static_completed` со статусом `success` |

**Payload:**

```json
{
  "task_id": "550e8400-e29b-41d4-a716-446655440000",
  "project_id": "11111111-2222-3333-4444-555555555555",
  "file_s3_path": "source-codes/project-uuid/file-uuid.c"
}
```

| Поле | Тип | Описание |
|------|-----|----------|
| `task_id` | UUID (string) | ID задачи (тот же, что и для static) |
| `project_id` | UUID (string) | ID проекта |
| `file_s3_path` | string | Путь к исходному файлу в MinIO |

---

### 4. `events.analysis.cache_completed`

| Параметр | Значение |
|----------|----------|
| **Producer** | Worker Cache Interpreter |
| **Consumer** | Analysis API |
| **Триггер** | Воркер завершил интерпретацию кэш-поведения |

**Payload (успех):**

```json
{
  "task_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "success",
  "artifact_s3_path": "analysis-artifacts/550e8400-e29b-41d4-a716-446655440000/cache-out.json"
}
```

**Payload (ошибка):**

```json
{
  "task_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "error",
  "error": "cache simulation timeout"
}
```

---

## Жизненный цикл задачи (State Machine)

```
[pending] → [static_running] → [static_done] → [cache_running] → [done]
                    ↓                                    ↓
                 [error]                              [error]
```

### Переходы статусов в Analysis DB:

1. `pending` — задача создана, файл загружен в MinIO
2. `static_running` — отправлено событие `start_static` в Kafka
3. `static_done` — получено `static_completed` с `status: success`
4. `cache_running` — отправлено событие `start_cache` в Kafka
5. `done` — получено `cache_completed` с `status: success`
6. `error` — любой из воркеров вернул `status: error`

---

## ClickHouse таблицы

### `analysis_metrics.static_patterns`
Результат статического анализа — множество строк на задачу, по строке на найденный
паттерн доступа в памяти. Заполняется `worker-static-analyzer` после AST-анализа.

### `analysis_metrics.dynamic_pattern_metrics`
Результат симуляции кэша — множество строк на задачу, по строке на каждый
`(pattern_fingerprint, cache_level)`. Заполняется `worker-cache-interpreter` после
запуска `valgrind --tool=cachegrind` на скомпилированном коде. Связь со статической
таблицей — по полю `pattern_fingerprint`, со статусом задачи — по `source_task_id`.

`analysis-api` агрегирует обе таблицы для `GET /api/v1/analysis/tasks/:id/metrics`:
`total_memory_accesses` берётся из `static_patterns`, `cache_misses` (L1) — из
`dynamic_pattern_metrics`.
