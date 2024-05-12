variable "github_pat" {
  type        = string
  nullable    = false
  description = "GitHub Personal Access Token with `read:packages` permission."
}

variable "gpg_key_email" {
  type    = string
  default = "github@developer-friendly.blog"
}

variable "gpg_key_name" {
  type    = string
  default = "Developer Friendly Bot"
}

variable "gpg_key_passphrase" {
  type    = string
  default = null
}

variable "gpg_key_rsa_bits" {
  type    = number
  default = 2048
}

variable "tls_private_key_algorithm" {
  type    = string
  default = "ED25519"
}

variable "github_repository_name" {
  type    = string
  default = "echo-server"
}

variable "ghcr_token_aws_ssm_name" {
  type    = string
  default = "/github/echo-server/ghcr-token"
}

variable "gpg_key_aws_ssm_name" {
  type    = string
  default = "/github/gpg-keys/developer-friendly-bot"
}

variable "github_owner" {
  type    = string
  default = "developer-friendly"
}

variable "github_owner_individual" {
  type    = string
  default = "developer-friendly-bot"
}

variable "deploy_key_ssm_name" {
  type    = string
  default = "/github/echo-server/deploy-key"
}
