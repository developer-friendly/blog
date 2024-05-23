output "aws_oidc_arn" {
  value = aws_iam_openid_connect_provider.this.arn
}

output "aws_role_arn" {
  value = aws_iam_role.this.arn
}

output "azure_tenant_id" {
  value = data.azuread_client_config.current.tenant_id
}

# output "token_audience" {
#   value = var.token_audience
# }

# output "token_subject" {
#   value = var.token_subject
# }

output "user_assigned_identity_id" {
  value = azurerm_user_assigned_identity.this.id
}
