variable "hetzner_api_token" {
  type      = string
  nullable  = false
  sensitive = true
}

variable "cloudflare_api_token" {
  type      = string
  nullable  = false
  sensitive = true
}

variable "stack_name" {
  type    = string
  default = "k3s-cluster"
}

variable "primary_ip_datacenter" {
  type    = string
  default = "nbg1-dc3"
}

variable "root_domain" {
  type    = string
  default = "developer-friendly.blog"
}

variable "server_datacenter" {
  type    = string
  default = "nbg1"
}

variable "username" {
  type    = string
  default = "k8s"
}
