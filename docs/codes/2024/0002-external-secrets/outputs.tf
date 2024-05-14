output "access_key" {
  value = aws_iam_access_key.this.id
}

output "secret_key" {
  value     = aws_iam_access_key.this.secret
  sensitive = true
}
