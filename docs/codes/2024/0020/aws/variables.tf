variable "vpc_id" {
  nullable = false
}

variable "authorized_ips" {
  type    = list(string)
  default = []
}
