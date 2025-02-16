variable "bucket_name" {
  type     = string
  nullable = false
}

variable "workload_identity_pool_id" {
  type     = string
  nullable = false
}

variable "github_repo" {
  type     = string
  nullable = false
  default  = "developer-friendly/frontend-in-gcp-bucket"
}
