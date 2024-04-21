output "iam_role_arn" {
  value = aws_iam_role.this.arn
}

output "service_account_namespace" {
  value = var.service_account_namespace
}

output "service_account_name" {
  value = var.service_account_name
}
