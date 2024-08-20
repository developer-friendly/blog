resource "null_resource" "bootstrap" {
  connection {
    type        = "ssh"
    host        = azurerm_public_ip.example.ip_address
    user        = "adminuser"
    private_key = tls_private_key.example.private_key_pem
  }

  provisioner "local-exec" {
    # To account for cloud-init operations in the new created VM
    command = "sleep 120"
  }

  provisioner "local-exec" {
    command = "cd ${local.cwd} && ansible-playbook bootstrap.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo waagent -deprovision+user -force",
    ]
  }

  provisioner "local-exec" {
    command = "az vm deallocate --resource-group ${azurerm_resource_group.example.name} --name example-machine"
  }

  provisioner "local-exec" {
    command = "az vm generalize --resource-group ${azurerm_resource_group.example.name} --name example-machine"
  }

  triggers = {
    vm_id = azurerm_linux_virtual_machine.example.id,
  }

  depends_on = [
    local_file.inventory,
    azurerm_linux_virtual_machine.example,
    azurerm_public_ip.example,
  ]
}
