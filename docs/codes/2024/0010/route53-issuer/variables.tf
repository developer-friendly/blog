variable "role_arn" {
  type    = string
  default = null
}

variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/config"
}

variable "kubeconfig_context" {
  type    = string
  default = "k3d-k3s-default"
}

variable "field_manager" {
  type    = string
  default = "flux-client-side-apply"
}

variable "access_token_audience" {
  type    = string
  default = "sts.amazonaws.com"
}

variable "chart_url" {
  type    = string
  default = "https://charts.jetstack.io"
}

variable "chart_name" {
  type    = string
  default = "cert-manager"
}

variable "release_name" {
  type    = string
  default = "cert-manager"
}

variable "release_namespace" {
  type    = string
  default = "cert-manager"
}

variable "release_version" {
  type    = string
  default = "v1.14.x"
}
