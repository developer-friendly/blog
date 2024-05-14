variable "github_pat" {
  type        = string
  nullable    = false
  description = "GitHub Personal Access Token with `read:packages` permission."
}

variable "gpg_key_passphrase" {
  type    = string
  default = null
}

variable "github_owner" {
  type        = string
  default     = "developer-friendly"
  description = "Can be an organization or a user."
}

variable "github_owner_individual" {
  type        = string
  default     = "developer-friendly-bot"
  description = "Can ONLY be a user."
}
