output "iam_role_arn" {
  value = aws_iam_role.this.arn
}

output "access_token_audience" {
  value = var.access_token_audience
}

output "service_account_name" {
  value = var.service_account_name
}

output "service_account_namespace" {
  value = var.service_account_namespace
}
