# Секреты

| Файл | В Git? | Назначение |
|------|--------|------------|
| `production.env` | **Нет** | Реальные пароли (сгенерированы) |
| `production.env.example` | Да | Шаблон |
| `external-secret.example.yaml` | Да | Пример External Secrets (Lockbox) |

## Быстрый старт

```bash
cd infra

# Уже сгенерировано — применить к .env и K8s:
chmod +x scripts/*.sh
./scripts/apply-secrets.sh

# Перегенерировать все пароли (перезапишет production.env!):
./scripts/generate-secrets.sh
./scripts/apply-secrets.sh
```

## Ключи в `diploma-platform-secrets` (Kubernetes)

- `JWT_SECRET` — 64 hex (256 bit)
- `POSTGRES_PASSWORD` — Managed PG + init-job
- `REDIS_PASSWORD` — Managed Redis
- `CLICKHOUSE_PASSWORD` — Managed ClickHouse
- `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` — in-cluster MinIO

**Не коммитьте** `production.env` и корневой `.env`.
