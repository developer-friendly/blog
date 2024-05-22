output "aws_oidc_arn" {
  value = aws_iam_openid_connect_provider.this.arn
}

output "aws_role_arn" {
  value = aws_iam_role.this.arn
}
