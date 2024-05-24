output "oidc_arn" {
  value = aws_iam_openid_connect_provider.this.arn
}

output "oidc_url" {
  value = aws_iam_openid_connect_provider.this.url
}
