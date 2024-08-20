variable "resource_group_name" {
  type    = string
  default = "developer-friendly-aks"
}

variable "location" {
  type    = string
  default = "Germany West Central"
}

variable "kubernetes_version" {
  type    = string
  default = "1.29"
}

variable "admin_username" {
  type    = string
  default = "admin"
}

variable "agents_count" {
  type    = number
  default = 1
  description = "Number of worker nodes as Azure calls it."
}

variable "agents_size" {
  type    = string
  default = "Standard_B2ms" # 2 vCPUs, 8 GiB memory
}

variable "prefix" {
  type    = string
  default = "developer-friendly"
}
