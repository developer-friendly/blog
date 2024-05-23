resource "azurerm_resource_group" "this" {
  name     = "aws-oidc-rg"
  location = "Germany West Central"
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
}

resource "azurerm_ssh_public_key" "this" {
  name                = "oidc-ssh-key"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  public_key          = tls_private_key.this.public_key_openssh
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = "oidc-vm"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  size                = "Standard_B2pts"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = azurerm_ssh_public_key.this.public_key
  }

  os_disk {
    caching              = "None"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
