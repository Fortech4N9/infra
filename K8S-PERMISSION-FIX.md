# Kubernetes: Permission denied — что сделать

Terraform создал VPC, PostgreSQL, Redis, ClickHouse, Container Registry, но **кластер MK8S не создался**:

```text
rpc error: code = PermissionDenied desc = Permission denied
```

## Причина

В каталоге `b1gpso1m43a5d0ig7ndp` роли `k8s.clusters.agent` выданы только **сервисным аккаунтам** Terraform, а вашему **пользователю** (через `yc init`) не хватает прав на создание Managed Kubernetes.

## Исправление (консоль YC)

1. [Консоль](https://console.cloud.yandex.ru/) → каталог **code-analysis-project** (или ваш folder).
2. **Права доступа** → **Назначить роли**.
3. Субъект: ваш аккаунт (email).
4. Роль: **`editor`** или **`managed-kubernetes.admin`** (минимум для создания кластера).
5. Сохранить.

Проверка:

```bash
yc resource-manager folder list-access-bindings b1gpso1m43a5d0ig7ndp
# в списке должен появиться ваш userAccount с editor или managed-kubernetes.admin
```

## Повторный apply

```bash
cd infra/terraform
export YC_TOKEN=$(yc iam create-token)
source ../secrets/production.env

terraform apply -auto-approve
```

После успеха:

```bash
terraform output -raw kubernetes_cluster_id
yc managed-kubernetes cluster get-credentials --id $(terraform output -raw kubernetes_cluster_id) --external --force
kubectl get nodes
```

Далее — `infra/DEPLOY-K8S.md` с шага 4 (секреты) и Helm/ArgoCD.
