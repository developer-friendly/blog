variable "pages_repository_full_name" {
  type        = string
  nullable    = false
  description = "In the format OWNER/REPOSITORY"
}

variable "pages_deploy_private_key" {
  type      = string
  sensitive = true
  nullable  = false
  description = "SSH private key with write access to the repository of GitHub Pages"
}
