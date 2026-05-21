resource "yandex_mdb_postgresql_cluster" "main" {
  name        = "${var.project_name}-pg16"
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.main.id

  config {
    version = "16"
    resources {
      resource_preset_id = var.postgres_preset
      disk_type_id       = "network-ssd"
      disk_size          = var.db_disk_gb
    }
  }

  host {
    zone      = var.zone_a
    subnet_id = yandex_vpc_subnet.a.id
  }

  host {
    zone      = var.zone_b
    subnet_id = yandex_vpc_subnet.b.id
  }

  security_group_ids = [yandex_vpc_security_group.managed_db.id]

  database {
    name = "core_db"
  }

  database {
    name = "analysis_db"
  }

  user {
    name     = "diplom"
    password = var.postgres_password

    permission {
      database_name = "core_db"
    }

    permission {
      database_name = "analysis_db"
    }
  }

  # Схемы таблиц (02-core-schema.sql, 03-analysis-schema.sql) применяются
  # отдельно: миграцией приложения или Job в Helm — Terraform создаёт только БД и пользователя.
}
