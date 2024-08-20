output "identity_id" {
  value = azurerm_user_assigned_identity.this.id
}

output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "location" {
  value = azurerm_resource_group.this.location
}

output "role_arn" {
  value = aws_iam_role.this.arn
}
