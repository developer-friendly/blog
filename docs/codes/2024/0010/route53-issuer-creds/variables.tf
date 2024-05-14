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
