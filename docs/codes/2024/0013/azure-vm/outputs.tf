output "vm_public_ip" {
  value = azurerm_public_ip.this.ip_address
}

output "ssh_private_key" {
  value     = tls_private_key.this.private_key_pem
  sensitive = true
}

output "ansible_inventory_yml" {
  value = <<-EOF
    oidc:
      hosts:
        ${azurerm_public_ip.this.ip_address}:
          ansible_host: ${azurerm_public_ip.this.ip_address}
          ansible_ssh_user: adminuser
          ansible_ssh_private_key_file: /tmp/oidc-vm.pem
          ansible_ssh_common_args: "-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PasswordAuthentication=no"
  EOF
}
