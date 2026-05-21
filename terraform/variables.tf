variable "folder_id" {
  description = "Yandex Cloud folder ID"
  type        = string
}

variable "cloud_id" {
  description = "Yandex Cloud cloud ID (для Container Registry)"
  type        = string
}

variable "environment" {
  description = "Имя окружения (production, staging)"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Префикс имён ресурсов"
  type        = string
  default     = "diploma"
}

# --- Сеть ---

variable "zone_a" {
  type    = string
  default = "ru-central1-a"
}

variable "zone_b" {
  type    = string
  default = "ru-central1-b"
}

variable "vpc_cidr" {
  type    = string
  default = "10.128.0.0/16"
}

variable "subnet_a_cidr" {
  type    = string
  default = "10.128.1.0/24"
}

variable "subnet_b_cidr" {
  type    = string
  default = "10.128.2.0/24"
}

# --- Kubernetes ---

variable "k8s_version" {
  type    = string
  default = "1.29"
}

variable "k8s_node_platform_id" {
  description = "Платформа ВМ узлов — только x86_64 (wine в воркерах)"
  type        = string
  default     = "standard-v3"
}

variable "k8s_node_cores" {
  type    = number
  default = 4
}

variable "k8s_node_memory_gb" {
  type    = number
  default = 8
}

variable "k8s_node_disk_gb" {
  type    = number
  default = 64
}

variable "k8s_node_min" {
  type    = number
  default = 2
}

variable "k8s_node_max" {
  type    = number
  default = 5
}

variable "k8s_node_initial" {
  type    = number
  default = 2
}

variable "k8s_public_ip" {
  description = "NAT для мастера/узлов (нужен для публичного Ingress)"
  type        = bool
  default     = true
}

# --- Managed DB (пароли только через TF_VAR_* или -var, не коммитить) ---

variable "postgres_password" {
  description = "Пароль пользователя diplom в Managed PostgreSQL"
  type        = string
  sensitive   = true
}

variable "redis_password" {
  description = "Пароль Managed Redis"
  type        = string
  sensitive   = true
}

variable "clickhouse_password" {
  description = "Пароль пользователя ClickHouse"
  type        = string
  sensitive   = true
}

variable "postgres_preset" {
  type    = string
  default = "s2.micro"
}

variable "redis_preset" {
  type    = string
  default = "hm1.nano"
}

variable "clickhouse_preset" {
  type    = string
  default = "s2.micro"
}

variable "db_disk_gb" {
  type    = number
  default = 20
}

variable "ssh_public_key" {
  description = "Опционально: SSH-ключ для отладки узлов K8s"
  type        = string
  default     = ""
}
