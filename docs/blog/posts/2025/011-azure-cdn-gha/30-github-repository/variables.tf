variable "azure_client_id" {
  type     = string
  nullable = false
}

variable "azure_subscription_id" {
  type     = string
  nullable = false
}

variable "azure_tenant_id" {
  type     = string
  nullable = false
}

variable "cdn_endpoint" {
  type     = string
  nullable = false
}

variable "cdn_profile_name" {
  type     = string
  nullable = false
}

variable "github_repo" {
  type     = string
  nullable = false
}

variable "resource_group" {
  type     = string
  nullable = false
}

variable "storage_account_name" {
  type     = string
  nullable = false
}
