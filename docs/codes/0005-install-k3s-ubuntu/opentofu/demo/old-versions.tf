terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }

  required_version = "<2"
}

variable "hetzner_api_token" {
  type      = string
  nullable  = false
  sensitive = true
}

provider "hcloud" {
  token = var.hetzner_api_token
}
