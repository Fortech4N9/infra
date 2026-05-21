# Сервисные аккаунты для Managed Kubernetes (Yandex Cloud)
resource "yandex_iam_service_account" "k8s_cluster" {
  name        = "${var.project_name}-k8s-cluster-sa"
  description = "SA for ${var.project_name} Kubernetes cluster"
}

resource "yandex_iam_service_account" "k8s_nodes" {
  name        = "${var.project_name}-k8s-nodes-sa"
  description = "SA for ${var.project_name} node group"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_cluster_agent" {
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_cluster.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_nodes_agent" {
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_nodes.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_vpc_public_admin" {
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_nodes.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_load_balancer_admin" {
  folder_id = var.folder_id
  role      = "load-balancer.admin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_nodes.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_container_registry_puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_nodes.id}"
}

resource "yandex_kubernetes_cluster" "main" {
  name        = "${var.project_name}-k8s"
  description = "Regional K8s for cache-analysis platform (${var.environment})"

  network_id = yandex_vpc_network.main.id

  master {
    regional {
      region = "ru-central1"

      location {
        zone      = var.zone_a
        subnet_id = yandex_vpc_subnet.a.id
      }

      location {
        zone      = var.zone_b
        subnet_id = yandex_vpc_subnet.b.id
      }
    }

    version   = var.k8s_version
    public_ip = var.k8s_public_ip

    security_group_ids = [yandex_vpc_security_group.k8s_nodes.id]
  }

  service_account_id      = yandex_iam_service_account.k8s_cluster.id
  node_service_account_id = yandex_iam_service_account.k8s_nodes.id

  release_channel = "REGULAR"
}

resource "yandex_kubernetes_node_group" "workers" {
  name        = "${var.project_name}-workers-amd64"
  description = "Worker nodes linux/amd64 for wine-based cache/static workers"
  cluster_id  = yandex_kubernetes_cluster.main.id

  instance_template {
    platform_id = var.k8s_node_platform_id

    # standard-v3 и аналоги — x86_64. Не используйте ARM-платформы (standard-v3a и т.п.).

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
    location {
      zone = var.zone_b
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true
  }
}
