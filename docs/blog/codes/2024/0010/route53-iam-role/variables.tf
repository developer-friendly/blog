variable "role_name" {
  type    = string
  default = "cert-manager"
}

variable "hosted_zone_id" {
  type        = string
  description = "The Hosted Zone ID that the role will have access to. Defaults to `*`."
  default     = "*"
}

variable "oidc_issuer_url" {
  type        = string
  description = "The OIDC issuer URL of the cert-manager Kubernetes Service Account token."
  nullable    = false
}

variable "access_token_audience" {
  type    = string
  default = "sts.amazonaws.com"
}

variable "service_account_name" {
  type        = string
  default     = "cert-manager"
  description = "The name of the service account."
}

variable "service_account_namespace" {
  type        = string
  default     = "cert-manager"
  description = "The namespace of the service account."
}
