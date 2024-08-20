variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "cluster_secret_store_name" {
  type    = string
  default = "aws-parameter-store"
}

variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/config"
}

variable "kubeconfig_context" {
  type    = string
  default = "developer-friendly-aks-admin"
}

variable "field_manager" {
  type    = string
  default = "flux-client-side-apply"
}
