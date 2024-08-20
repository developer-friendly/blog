resource "random_password" "this" {
  length  = var.token_length
  special = false
}

resource "aws_ssm_parameter" "this" {
  name  = "/github/developer-friendly/blog/flux-system/receiver/token"
  value = random_password.this.result
  type  = "SecureString"
}
