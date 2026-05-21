#!/usr/bin/env bash
# Применяет secrets/production.env: локальный .env и (опционально) K8s Secret
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ROOT}/secrets/production.env"
K8S_NS="${K8S_NAMESPACE:-diploma}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}. Run: ./scripts/generate-secrets.sh" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "${ENV_FILE}"

# --- Локальный docker compose ---
LOCAL_ENV="${ROOT}/.env"
if [[ -f "${ROOT}/.env.example" ]]; then
  cp "${ROOT}/.env.example" "${LOCAL_ENV}"
fi

set_kv() {
  local key="$1" val="$2"
  if grep -q "^${key}=" "${LOCAL_ENV}" 2>/dev/null; then
    sed -i.bak "s|^${key}=.*|${key}=${val}|" "${LOCAL_ENV}" && rm -f "${LOCAL_ENV}.bak"
  else
    echo "${key}=${val}" >> "${LOCAL_ENV}"
  fi
}

set_kv POSTGRES_PASSWORD "${POSTGRES_PASSWORD}"
set_kv REDIS_PASSWORD "${REDIS_PASSWORD}"
set_kv CLICKHOUSE_PASSWORD "${CLICKHOUSE_PASSWORD}"
set_kv MINIO_ROOT_USER "${MINIO_ROOT_USER}"
set_kv MINIO_ROOT_PASSWORD "${MINIO_ROOT_PASSWORD}"
set_kv JWT_SECRET "${JWT_SECRET}"

chmod 600 "${LOCAL_ENV}"
echo "Updated local: ${LOCAL_ENV}"

# --- Kubernetes (если kubectl доступен) ---
if command -v kubectl >/dev/null 2>&1 && kubectl cluster-info >/dev/null 2>&1; then
  kubectl create namespace "${K8S_NS}" --dry-run=client -o yaml | kubectl apply -f -
  kubectl create secret generic diploma-platform-secrets -n "${K8S_NS}" \
    --from-literal=JWT_SECRET="${JWT_SECRET}" \
    --from-literal=POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
    --from-literal=REDIS_PASSWORD="${REDIS_PASSWORD}" \
    --from-literal=CLICKHOUSE_PASSWORD="${CLICKHOUSE_PASSWORD}" \
    --from-literal=MINIO_ROOT_USER="${MINIO_ROOT_USER}" \
    --from-literal=MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD}" \
    --dry-run=client -o yaml | kubectl apply -f -
  echo "Applied K8s secret diploma-platform-secrets in namespace ${K8S_NS}"
else
  echo "kubectl not configured — skip K8s secret (run manually from DEPLOY-K8S.md)"
fi

echo ""
echo "Terraform:"
echo "  export TF_VAR_postgres_password='${POSTGRES_PASSWORD}'"
echo "  export TF_VAR_redis_password='${REDIS_PASSWORD}'"
echo "  export TF_VAR_clickhouse_password='${CLICKHOUSE_PASSWORD}'"
