variable "username" {
  default = "my-user"
  type    = string
}

variable "secret_name" {
  default = "aws-ssm-user"
  type    = string
}

variable "secret_namespace" {
  default = "default"
  type    = string
}

variable "external_secret_name" {
  default = "aws-parameter-store"
  type    = string
}
