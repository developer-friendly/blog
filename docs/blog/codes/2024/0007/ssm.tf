resource "aws_ssm_parameter" "this" {
  name  = var.ssm_demo_parameter
  type  = "String"
  value = "This is not a secret, nor secure!"
}
