resource "yandex_mdb_clickhouse_cluster" "main" {
  name        = "${var.project_name}-clickhouse"
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.main.id

  clickhouse {
    resources {
      resource_preset_id = var.clickhouse_preset
      disk_type_id       = "network-ssd"
      disk_size          = var.db_disk_gb
    }
  }

  host {
    type      = "CLICKHOUSE"
    zone      = var.zone_a
    subnet_id = yandex_vpc_subnet.a.id
  }

  host {
    type      = "CLICKHOUSE"
    zone      = var.zone_b
    subnet_id = yandex_vpc_subnet.b.id
  }

  host {
    type      = "CLICKHOUSE"
    zone      = var.zone_d
    subnet_id = yandex_vpc_subnet.d.id
  }

  database {
    name = "analysis_metrics"
  }

  user {
    name     = var.clickhouse_user
    password = var.clickhouse_password

    permission {
      database_name = "analysis_metrics"
    }
  }

  security_group_ids = [yandex_vpc_security_group.managed_db.id]

  # DDL из init.sql выполняется Helm hook job-clickhouse-init при деплое.
}
