#!/usr/bin/env bash
# Генерирует secrets/production.env (в .gitignore). Перезаписывает файл!
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${ROOT}/secrets/production.env"

rand() {
  openssl rand -base64 48 | tr -d '/+=' | head -c "${1:-40}"
}

JWT_SECRET="$(openssl rand -hex 32)"
POSTGRES_PASSWORD="$(rand 40)"
REDIS_PASSWORD="$(rand 40)"
CLICKHOUSE_PASSWORD="$(rand 40)"
MINIO_ROOT_USER="diploma-minio"
MINIO_ROOT_PASSWORD="$(rand 40)"

cat > "${OUT}" <<EOF
# Сгенерировано: $(date -u +"%Y-%m-%dT%H:%M:%SZ") — НЕ КОММИТИТЬ

JWT_SECRET=${JWT_SECRET}

POSTGRES_USER=diplom
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
CORE_DB_NAME=core_db
ANALYSIS_DB_NAME=analysis_db

REDIS_PASSWORD=${REDIS_PASSWORD}

CLICKHOUSE_USER=default
CLICKHOUSE_PASSWORD=${CLICKHOUSE_PASSWORD}
CLICKHOUSE_DB=analysis_metrics

MINIO_ROOT_USER=${MINIO_ROOT_USER}
MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}

TF_VAR_postgres_password=${POSTGRES_PASSWORD}
TF_VAR_redis_password=${REDIS_PASSWORD}
TF_VAR_clickhouse_password=${CLICKHOUSE_PASSWORD}
EOF

chmod 600 "${OUT}"
echo "Written: ${OUT}"
echo "Next: source ${OUT}  OR  ./scripts/apply-secrets.sh"
