resource "yandex_container_registry" "main" {
  name = "${var.project_name}-registry"
}

resource "yandex_container_repository" "core_api" {
  name = "${yandex_container_registry.main.id}/core-api"
}

resource "yandex_container_repository" "analysis_api" {
  name = "${yandex_container_registry.main.id}/analysis-api"
}

resource "yandex_container_repository" "frontend" {
  name = "${yandex_container_registry.main.id}/frontend"
}

resource "yandex_container_repository" "worker_static" {
  name = "${yandex_container_registry.main.id}/worker-static"
}

resource "yandex_container_repository" "worker_cache" {
  name = "${yandex_container_registry.main.id}/worker-cache"
}

resource "yandex_iam_service_account" "ci_pusher" {
  name        = "${var.project_name}-ci-pusher"
  description = "GitHub Actions: push images to YCR"
}

resource "yandex_container_registry_iam_binding" "ci_pusher" {
  registry_id = yandex_container_registry.main.id
  role        = "container-registry.images.pusher"
  members = [
    "serviceAccount:${yandex_iam_service_account.ci_pusher.id}",
  ]
}

# Ключ SA для GitHub Secret YC_SA_JSON_KEY — выводится в output (sensitive)
resource "yandex_iam_service_account_key" "ci_pusher_key" {
  service_account_id = yandex_iam_service_account.ci_pusher.id
  description        = "GitHub Actions YCR push"
}
