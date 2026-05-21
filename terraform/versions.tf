terraform {
  required_version = ">= 1.5.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.130"
    }
  }

  # Раскомментируйте после создания бакета в Yandex Object Storage для state.
  # backend "s3" {
  #   endpoints = { s3 = "https://storage.yandexcloud.net" }
  #   bucket    = "diploma-terraform-state"
  #   key       = "production/terraform.tfstate"
  #   region    = "ru-central1"
  #   skip_region_validation      = true
  #   skip_credentials_validation = true
  # }
}
