output "admin_username" {
  value = random_pet.admin_username.id
}

output "private_ip_address" {
  value = azurerm_network_interface.this.ip_configuration[0].private_ip_address
}

output "ssh_private_key" {
  value     = tls_private_key.this.private_key_pem
  sensitive = true
}

output "resource_group_name" {
  value = data.azurerm_resource_group.this.name
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.this.id
}
