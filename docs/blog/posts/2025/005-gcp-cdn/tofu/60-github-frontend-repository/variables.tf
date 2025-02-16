variable "google_service_account_email" {
  type     = string
  nullable = false
}

variable "workload_identity_pool_provider_id" {
  type     = string
  nullable = false
}

variable "google_storage_bucket" {
  type     = string
  nullable = false
}
