resource "yandex_vpc_network" "main" {
  name        = "${var.project_name}-vpc"
  description = "VPC for ${var.project_name} platform (${var.environment})"
}

resource "yandex_vpc_subnet" "a" {
  name           = "${var.project_name}-subnet-a"
  zone           = var.zone_a
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.subnet_a_cidr]
}

resource "yandex_vpc_subnet" "b" {
  name           = "${var.project_name}-subnet-b"
  zone           = var.zone_b
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.subnet_b_cidr]
}

resource "yandex_vpc_security_group" "k8s_nodes" {
  name       = "${var.project_name}-k8s-nodes-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    protocol       = "ANY"
    description    = "Intra-VPC"
    v4_cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTPS from Internet (Ingress)"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTP from Internet (cert-manager HTTP-01)"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  egress {
    protocol       = "ANY"
    description    = "Egress"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "managed_db" {
  name       = "${var.project_name}-managed-db-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    protocol          = "TCP"
    description       = "PostgreSQL from K8s nodes"
    security_group_id = yandex_vpc_security_group.k8s_nodes.id
    port              = 6432
  }

  ingress {
    protocol          = "TCP"
    description       = "Redis from K8s nodes"
    security_group_id = yandex_vpc_security_group.k8s_nodes.id
    port              = 6379
  }

  ingress {
    protocol          = "TCP"
    description       = "ClickHouse HTTP from K8s nodes"
    security_group_id = yandex_vpc_security_group.k8s_nodes.id
    port              = 8123
  }

  ingress {
    protocol          = "TCP"
    description       = "ClickHouse native from K8s nodes"
    security_group_id = yandex_vpc_security_group.k8s_nodes.id
    port              = 9000
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
