# Сервисные аккаунты для Managed Kubernetes (Yandex Cloud)
resource "yandex_iam_service_account" "k8s_cluster" {
  name        = "${var.project_name}-k8s-cluster-sa"
  description = "SA for ${var.project_name} Kubernetes cluster"
}

resource "yandex_iam_service_account" "k8s_nodes" {
  name        = "${var.project_name}-k8s-nodes-sa"
  description = "SA for ${var.project_name} node group"
}

# --- ВЫДАЧА ПРАВ СЕРВИСНЫМ АККАУНТАМ ---

# Даем полные права (editor) кластеру, чтобы он мог сам создавать балансировщики и IP-адреса
resource "yandex_resourcemanager_folder_iam_member" "k8s_cluster_editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_cluster.id}"
}

# Даем права (editor) нодам, чтобы они могли качать образы из YCR и писать логи
resource "yandex_resourcemanager_folder_iam_member" "k8s_nodes_editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_nodes.id}"
}

# --- СОЗДАНИЕ КЛАСТЕРА ---

resource "yandex_kubernetes_cluster" "main" {
  name        = "${var.project_name}-k8s-v2"
  description = "Zonal K8s (amd64) for cache-analysis platform (${var.environment})"

  network_id = yandex_vpc_network.main.id

  # Безопасные IP-диапазоны, которые мы подобрали
  cluster_ipv4_range = "10.200.0.0/16"
  service_ipv4_range = "10.201.0.0/16"

  master {
    zonal {
      zone      = var.zone_a
      subnet_id = yandex_vpc_subnet.a.id
    }

    version   = var.k8s_version
    public_ip = var.k8s_public_ip

    security_group_ids = [yandex_vpc_security_group.k8s_nodes.id]
  }

  service_account_id      = yandex_iam_service_account.k8s_cluster.id
  node_service_account_id = yandex_iam_service_account.k8s_nodes.id

  release_channel = "REGULAR"

  # Ждем, пока Яндекс применит права, прежде чем создавать кластер
  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s_cluster_editor,
    yandex_resourcemanager_folder_iam_member.k8s_nodes_editor
  ]
}

# --- СОЗДАНИЕ УЗЛОВ (ВОРКЕРОВ) ---

resource "yandex_kubernetes_node_group" "workers" {
  name        = "${var.project_name}-workers-amd64"
  description = "Worker nodes linux/amd64 for wine-based cache/static workers"
  cluster_id  = yandex_kubernetes_cluster.main.id

  instance_template {
    platform_id = var.k8s_node_platform_id

    resources {
      cores  = var.k8s_node_cores
      memory = var.k8s_node_memory_gb
    }

    boot_disk {
      type = "network-ssd"
      size = var.k8s_node_disk_gb
    }

    network_interface {
      nat                = var.k8s_public_ip
      subnet_ids         = [yandex_vpc_subnet.a.id]
      security_group_ids = [yandex_vpc_security_group.k8s_nodes.id]
    }

    container_runtime {
      type = "containerd"
    }

    metadata = {
      ssh-keys = var.ssh_public_key != "" ? "ubuntu:${var.ssh_public_key}" : null
    }
  }

  scale_policy {
    auto_scale {
      min     = var.k8s_node_min
      max     = var.k8s_node_max
      initial = var.k8s_node_initial
    }
  }

  allocation_policy {
    location {
      zone = var.zone_a
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true
  }
}
