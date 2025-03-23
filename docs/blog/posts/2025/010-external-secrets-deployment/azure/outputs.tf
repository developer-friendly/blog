output "tenant_id" {
  value = data.azurerm_subscription.current.tenant_id
}

output "client_id" {
  value = azurerm_user_assigned_identity.this.client_id
}
