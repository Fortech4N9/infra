output "vpc_id" {
  value = yandex_vpc_network.main.id
}

output "subnet_a_id" {
  value = yandex_vpc_subnet.a.id
}

output "subnet_b_id" {
  value = yandex_vpc_subnet.b.id
}

output "kubernetes_cluster_id" {
  value = yandex_kubernetes_cluster.main.id
}

output "kubernetes_external_v4_endpoint" {
  description = "kubectl endpoint"
  value       = yandex_kubernetes_cluster.main.master[0].external_v4_endpoint
}

output "container_registry_id" {
  value = yandex_container_registry.main.id
}

output "container_registry_url" {
  description = "Префикс для образов: cr.yandex/<registry_id>/"
  value       = "cr.yandex/${yandex_container_registry.main.id}"
}

output "postgres_host_fqdn" {
  value = yandex_mdb_postgresql_cluster.main.host[0].fqdn
}

output "postgres_port" {
  value = 6432
}

output "redis_host_fqdn" {
  value = yandex_mdb_redis_cluster.main.host[0].fqdn
}

output "clickhouse_host_fqdn" {
  value = yandex_mdb_clickhouse_cluster.main.host[0].fqdn
}

output "ci_service_account_key" {
  description = "JSON для GitHub Secret YC_SA_JSON_KEY"
  value       = yandex_iam_service_account_key.ci_pusher_key.private_key
  sensitive   = true
}

output "helm_external_endpoints" {
  description = "Подставьте в helm/diploma-platform/values.yaml (секреты — отдельно)"
  value = {
    postgres_host    = yandex_mdb_postgresql_cluster.main.host[0].fqdn
    redis_host       = yandex_mdb_redis_cluster.main.host[0].fqdn
    clickhouse_host  = yandex_mdb_clickhouse_cluster.main.host[0].fqdn
    image_registry   = "cr.yandex/${yandex_container_registry.main.id}"
  }
}
