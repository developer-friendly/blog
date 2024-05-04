output "iam_user_arn" {
  value = aws_iam_user.this.arn
}

output "iam_access_key_id" {
  value     = aws_iam_access_key.this.id
  sensitive = true
}

output "iam_access_key_secret" {
  value     = aws_iam_access_key.this.secret
  sensitive = true
}
