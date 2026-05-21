# Мануал развёртывания (Yandex Cloud + Kubernetes + GitOps)

Пошаговые команды для запуска **с вашей машины** (нужен VPN/доступ к Yandex Cloud).  
Код инфраструктуры: репозиторий **`infra`** (submodule `Fortech4N9/infra`). Локально: каталог `infra/` в монорепо.

---

## Предварительные требования

Установите:

- [Yandex Cloud CLI](https://cloud.yandex.ru/docs/cli/quickstart) — `yc`
- Terraform ≥ 1.5
- `kubectl`, `helm` ≥ 3.12
- `docker` (для локальной сборки образов, опционально)

Запишите:

- `folder_id`, `cloud_id` из консоли YC
- Домен: `code-analysis-project.ru` (DNS у регистратора)

---

## Шаг 1. Авторизация в Yandex Cloud

```bash
yc init
export YC_FOLDER_ID="b1gxxxxxxxx"
export YC_CLOUD_ID="b1gxxxxxxxx"
export YC_TOKEN=$(yc iam create-token)
```

Для Terraform (один из вариантов):

```bash
export YC_TOKEN=$(yc iam create-token)
# либо положите ключ SA: export YC_SERVICE_ACCOUNT_KEY_FILE=~/sa-key.json
```

---

## Шаг 2. Terraform — VPC, K8s, YCR, Managed DB

```bash
cd infra/terraform

cp terraform.tfvars.example terraform.tfvars
# Отредактируйте terraform.tfvars: folder_id, cloud_id

export TF_VAR_postgres_password='ВАШ_СЛОЖНЫЙ_ПАРОЛЬ'
export TF_VAR_redis_password='ВАШ_СЛОЖНЫЙ_ПАРОЛЬ'
export TF_VAR_clickhouse_password='ВАШ_СЛОЖНЫЙ_ПАРОЛЬ'

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Сохраните вывод (без публикации паролей):

```bash
terraform output -json | tee ../outputs.json
terraform output -raw container_registry_url
terraform output -json helm_external_endpoints
terraform output -raw ci_service_account_key > ../yc-ci-key.json
chmod 600 ../yc-ci-key.json
```

**Время:** 30–60+ минут.  
**Важно:** узлы K8s — **amd64** (`standard-v3`), для воркеров с Wine.

---

## Шаг 3. kubectl — доступ к кластеру

```bash
export CLUSTER_ID=$(cd terraform && terraform output -raw kubernetes_cluster_id)

yc managed-kubernetes cluster get-credentials \
  --id "$CLUSTER_ID" \
  --external \
  --force

kubectl get nodes -o wide
```

Убедитесь: все ноды `Ready`, архитектура **amd64**.

---

## Шаг 4. Namespace и секреты (не в Git!)

```bash
kubectl create namespace diploma
kubectl create namespace argocd
kubectl create namespace monitoring
```

Подставьте **те же пароли**, что в `TF_VAR_*`:

```bash
kubectl create secret generic diploma-platform-secrets -n diploma \
  --from-literal=JWT_SECRET='замените_256bit_секрет' \
  --from-literal=POSTGRES_PASSWORD='как_TF_VAR_postgres_password' \
  --from-literal=REDIS_PASSWORD='как_TF_VAR_redis_password' \
  --from-literal=CLICKHOUSE_PASSWORD='как_TF_VAR_clickhouse_password' \
  --from-literal=MINIO_ROOT_USER='minioadmin' \
  --from-literal=MINIO_ROOT_PASSWORD='замените_minio_пароль'
```

Для pull из YCR (приватный реестр):

```bash
yc container registry configure-docker

kubectl create secret docker-registry ycr-pull-secret -n diploma \
  --docker-server=cr.yandex \
  --docker-username=json_key \
  --docker-password="$(cat ../yc-ci-key.json)" \
  --docker-email=ci@diploma.local
```

---

## Шаг 5. Подготовить Helm values

```bash
cd infra/helm/diploma-platform

# Зависимости (Kafka, MinIO)
helm dependency update

# Отредактируйте values.yaml:
# - global.imageRegistry: cr.yandex/<REGISTRY_ID>  (из terraform output)
# - external.postgres.host / redis.host / clickhouse.host (из helm_external_endpoints)
```

Пример подстановки через `yq` (подставьте FQDN из `terraform output`):

```bash
REGISTRY_ID=$(cd ../../terraform && terraform output -raw container_registry_id)
PG_HOST=$(cd ../../terraform && terraform output -raw postgres_host_fqdn)
REDIS_HOST=$(cd ../../terraform && terraform output -raw redis_host_fqdn)
CH_HOST=$(cd ../../terraform && terraform output -raw clickhouse_host_fqdn)

yq e ".global.imageRegistry = \"cr.yandex/${REGISTRY_ID}\"" -i values.yaml
yq e ".external.postgres.host = \"${PG_HOST}\"" -i values.yaml
yq e ".external.redis.host = \"${REDIS_HOST}\"" -i values.yaml
yq e ".external.clickhouse.host = \"${CH_HOST}\"" -i values.yaml
```

---

## Шаг 6. ArgoCD (платформенные компоненты + приложение)

### 6.1 Установить Argo CD

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
```

Пароль admin (первый вход):

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo
```

Порт-форвард UI (опционально):

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# https://localhost:8080  user: admin
```

### 6.2 Заменить URL репозитория в манифестах

В файлах `argocd/apps/*.yaml` и `argocd/infrastructure/cluster-issuer.yaml` замените  
`https://github.com/YOUR_ORG/infra.git` на ваш реальный репозиторий.

### 6.3 Применить App of Apps

```bash
cd infra

# Сначала инфраструктура кластера (Ingress, cert-manager, мониторинг)
kubectl apply -f argocd/apps/infrastructure.yaml

# Затем платформа (после готовности Ingress и секретов)
kubectl apply -f argocd/apps/platform.yaml

# Или оба через root (без self-sync root-app):
kubectl apply -f argocd/apps/root-app.yaml
```

Проверка:

```bash
kubectl get applications -n argocd
kubectl get pods -n ingress-nginx
kubectl get pods -n diploma
kubectl get ingress -n diploma
```

### 6.4 DNS и TLS

Узнайте внешний IP Ingress:

```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

В DNS регистратора:

```
A  code-analysis-project.ru  ->  <EXTERNAL-IP>
```

Дождитесь выпуска сертификата:

```bash
kubectl describe certificate -n diploma diploma-platform-tls
```

---

## Шаг 7. Ручной деплой Helm (без ArgoCD)

Если ArgoCD пока не используете:

```bash
cd infra/helm/diploma-platform
helm dependency update

helm upgrade --install diploma-platform . \
  --namespace diploma \
  --create-namespace \
  -f values.yaml \
  --wait --timeout 15m
```

Проверка init-job:

```bash
kubectl get jobs -n diploma
kubectl logs -n diploma job/diploma-platform-clickhouse-init
kubectl logs -n diploma job/diploma-platform-minio-init
kubectl logs -n diploma job/diploma-platform-postgres-init
```

---

## Шаг 8. Сборка и push образов (локально)

```bash
yc container registry configure-docker
export REGISTRY_ID=$(cd infra/terraform && terraform output -raw container_registry_id)
export TAG=$(git -C /path/to/gybryd-analytic rev-parse --short HEAD)

# core-api
docker build --platform linux/amd64 \
  -t cr.yandex/${REGISTRY_ID}/core-api:${TAG} \
  ./core-api
docker push cr.yandex/${REGISTRY_ID}/core-api:${TAG}

# analysis-api
docker build --platform linux/amd64 \
  -t cr.yandex/${REGISTRY_ID}/analysis-api:${TAG} \
  ./analysis-api
docker push cr.yandex/${REGISTRY_ID}/analysis-api:${TAG}

# frontend
docker build --platform linux/amd64 \
  -t cr.yandex/${REGISTRY_ID}/frontend:${TAG} \
  ./frontend
docker push cr.yandex/${REGISTRY_ID}/frontend:${TAG}

# worker-static (нужен базовый образ keplar01/static-analyzer:latest)
docker build --platform linux/amd64 \
  -t cr.yandex/${REGISTRY_ID}/worker-static:${TAG} \
  ./static-analysis-worker
docker push cr.yandex/${REGISTRY_ID}/worker-static:${TAG}

# worker-cache (долгая сборка: ubuntu + wine + cats)
docker build --platform linux/amd64 \
  -t cr.yandex/${REGISTRY_ID}/worker-cache:${TAG} \
  ./cache-analysis-worker
docker push cr.yandex/${REGISTRY_ID}/worker-cache:${TAG}
```

Обновите теги в `values.yaml` и сделайте `helm upgrade` или дождитесь ArgoCD sync.

---

## Шаг 9. GitHub Actions (CI → GitOps)

В **каждом** репозитории сервиса (`core-api`, `analysis-api`, `frontend`, workers) добавьте Secrets:

| Secret | Значение |
|--------|----------|
| `YC_SA_JSON_KEY` | содержимое `yc-ci-key.json` |
| `YC_REGISTRY_ID` | ID реестра из `terraform output container_registry_id` |
| `PAT_TOKEN` | GitHub PAT с `repo` на `infra` |
| `INFRA_REPO` | `Fortech4N9/infra` (ваш org/repo) |

При push в `main` workflow:

1. Собирает образ `linux/amd64`
2. Пушит в `cr.yandex/<ID>/<service>:<sha>`
3. Обновляет тег в `infra/helm/diploma-platform/values.yaml`
4. ArgoCD подхватывает изменение

---

## Шаг 10. Проверка работоспособности

```bash
# Поды
kubectl get pods -n diploma

# Ingress
curl -k https://code-analysis-project.ru/health

# Логи воркеров (OOM — смотреть в Loki после установки loki-stack)
kubectl logs -n diploma deploy/worker-static --tail=100
kubectl logs -n diploma deploy/worker-cache --tail=100

# Kafka
kubectl exec -n diploma deploy/kafka-controller-0 -- kafka-topics.sh --bootstrap-server localhost:9092 --list
```

В браузере: `https://code-analysis-project.ru` — логин, проект, загрузка `.c`, статус пайплайна.

---

## Частые проблемы

| Симптом | Что проверить |
|---------|----------------|
| `ImagePullBackOff` | `ycr-pull-secret`, тег образа в values |
| 413 при upload | аннотация `proxy-body-size: 50m` на Ingress |
| Воркер падает OOM | limits 512Mi — ожидаемо; логи в Loki |
| Wine не работает | нода **amd64**, не ARM |
| ClickHouse init fail | FQDN, пароль, порт 9000, security groups |
| Postgres SSL | Managed PG на 6432; при необходимости добавьте `sslmode` в приложение |

---

## Структура репозитория infra

```
infra/
├── DEPLOY.md                 # этот мануал
├── terraform/                # YC: VPC, K8s, YCR, PG, Redis, CH
├── helm/diploma-platform/    # приложение + Kafka + MinIO
├── argocd/                   # GitOps манифесты
├── secrets/                  # примеры (без реальных паролей)
└── .github/                  # (опционально) общие workflow
```

---

## Порядок «с нуля» (кратко)

```bash
yc init
cd infra/terraform && terraform apply
yc managed-kubernetes cluster get-credentials --id $(terraform output -raw kubernetes_cluster_id) --external --force
kubectl create namespace diploma && kubectl create secret generic diploma-platform-secrets ...
helm dependency update helm/diploma-platform && # правка values.yaml
kubectl apply -f argocd/apps/infrastructure.yaml
kubectl apply -f argocd/apps/platform.yaml
# DNS -> IP Ingress, дождаться TLS
# docker build/push или GitHub Actions
```

Готово.
