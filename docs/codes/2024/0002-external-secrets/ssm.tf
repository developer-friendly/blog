variable "mongo_root_password" {
  type      = string
  sensitive = true
  default   = "ThisIsNotASecurePassword"
}

resource "aws_ssm_parameter" "this" {
  name  = "/prod/mongodb-atlas/passwords/root"
  type  = "SecureString"
  value = var.mongo_root_password
}
