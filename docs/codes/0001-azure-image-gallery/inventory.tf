locals {
  cwd = path.cwd
  key_filepath = "${path.cwd}/azure_vm.key"
}

resource "local_sensitive_file" "ssh_private_key" {
  content         = tls_private_key.this.private_key_pem
  filename        = local.key_filepath
  file_permission = "0400"
}


resource "local_file" "inventory" {
  content = <<-EOT
    azure:
      hosts:
        azure-vm0:
          ansible_host: ${azurerm_public_ip.this.ip_address}
          ansible_user: adminuser
          ansible_ssh_private_key_file: ${local.key_filepath}
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
  EOT

  filename        = "${local.cwd}/inventory.yml"
  file_permission = "0640"
}
