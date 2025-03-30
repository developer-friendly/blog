output "cdn_endpoint" {
  value = azurerm_cdn_endpoint.this.name
}

output "cdn_profile_name" {
  value = azurerm_cdn_profile.this.name
}

output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "subscription_id" {
  value = data.azurerm_client_config.current.subscription_id
}

output "url" {
  value = format("https://%s", azurerm_cdn_endpoint.this.fqdn)
}
