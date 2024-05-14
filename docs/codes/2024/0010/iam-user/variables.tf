variable "user_name" {
  type    = string
  default = "cert-manager"
}

variable "hosted_zone_id" {
  type        = string
  description = "The Hosted Zone ID that the role will have access to. Defaults to `*`."
  default     = "*"
}
