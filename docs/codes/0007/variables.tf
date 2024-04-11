variable "github_owner" {
  description = "The account username or organization name"
  default     = "developer-friendly"
}

variable "github_repository" {
  description = "The repository name"
  default     = "oidc-github-aws"
}

variable "ssm_demo_parameter" {
  description = "The SSM parameter name"
  default     = "/some/parameter/in/aws/ssm"
}
