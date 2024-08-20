variable "oidc_issuer_url" {
  type        = string
  default     = null
  description = "The OIDC issuer URL. Pass this value to override the one received from the aks/terraform.tfstate file."
}

variable "access_token_audience" {
  type        = string
  default     = "sts.amazonaws.com"
  description = "The audience for the tokens issued by the identity provider in the AKS cluster."
}

variable "iam_role_name" {
  type        = string
  default     = "external-secrets"
  description = "The name of the IAM role."
}

variable "service_account_namespace" {
  type        = string
  default     = "external-secrets"
  description = "The namespace of the service account."
}

variable "service_account_name" {
  type        = string
  default     = "external-secrets"
  description = "The name of the service account."
}
