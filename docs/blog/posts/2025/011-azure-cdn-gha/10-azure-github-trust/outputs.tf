output "client_id" {
  value = azuread_application.this.client_id
}

output "service_principal_guid" {
  value = azuread_service_principal.this.object_id
}

output "tenant_id" {
  value = data.azuread_client_config.current.tenant_id
}
