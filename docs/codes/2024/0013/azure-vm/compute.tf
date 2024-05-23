resource "tls_private_key" "this" {
  algorithm = "RSA"
}

resource "azurerm_ssh_public_key" "this" {
  name                = "oidc-ssh-key"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  public_key          = tls_private_key.this.public_key_openssh
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = "oidc-vm"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  size                = "Standard_B2pts_v2"
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

  # https://learn.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage
  source_image_reference {
    publisher = "Debian"
    offer     = "debian-13-daily"
    sku       = "13-arm64"
    version   = "latest"

  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    az login -i --allow-no-subscriptions
    apt update
    apt upgrade -y
    apt install -y jq
  EOF
  )

  identity {
    type = "UserAssigned"
    identity_ids = [
      local.identity_id,
    ]
  }
}
