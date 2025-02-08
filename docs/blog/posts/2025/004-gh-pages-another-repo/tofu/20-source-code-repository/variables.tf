variable "pages_repository_full_name" {
  type     = string
  nullable = false
}

variable "pages_deploy_private_key" {
  type      = string
  sensitive = true
  nullable  = false
}
