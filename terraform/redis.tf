resource "yandex_mdb_redis_cluster" "main" {
  name        = "${var.project_name}-redis7"
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.main.id

  config {
    version = "7.2"
    password = var.redis_password
    resources {
      resource_preset_id = var.redis_preset
      disk_type_id       = "network-ssd"
      disk_size          = 16
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
}
