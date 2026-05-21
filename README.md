# infra

Единый репозиторий инфраструктуры платформы анализа кэш-поведения C-кода.

## Локальная разработка (Docker Compose)

```bash
cp .env.example .env
make up
```

Gateway: http://localhost:8080 (порт из `.env` → `NGINX_PORT`).

## Документация

| Документ | Содержание |
|----------|------------|
| **[MANUAL.md](./MANUAL.md)** | Полный мануал: архитектура, секреты (без значений), Terraform, Helm, ArgoCD, CI |
| **[DEPLOY-K8S.md](./DEPLOY-K8S.md)** | Шпаргалка команд для production |

## Production (Yandex Cloud + Kubernetes)

| Каталог | Назначение |
|---------|------------|
| `terraform/` | VPC, Managed K8s (amd64), YCR, PostgreSQL, Redis, ClickHouse |
| `helm/diploma-platform/` | Микросервисы + Kafka + MinIO + Ingress |
| `argocd/` | GitOps: Ingress, TLS, мониторинг, приложение |
| `secrets/` | Примеры ключей секрета (без реальных паролей) |
| `docker-compose.yml` | Локальный стек (dev) |
| `postgres/`, `clickhouse/`, `minio/` | Init-скрипты (compose + Helm hooks) |

## CI (GitHub Actions)

В репозиториях сервисов workflow пушит образ в YCR и обновляет `helm/diploma-platform/values.yaml` в **этом** репо.

Secrets: `YC_SA_JSON_KEY`, `YC_REGISTRY_ID`, `PAT_TOKEN`, `INFRA_REPO` (= `Fortech4N9/infra`).
