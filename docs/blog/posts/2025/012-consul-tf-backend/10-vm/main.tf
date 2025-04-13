##########################################################
# PARENT
##########################################################
resource "azurerm_resource_group" "this" {
  name     = "rg-tf-state-backend"
  location = "Germany West Central"
}

##########################################################
# SECRETS
##########################################################
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_ssh_public_key" "this" {
  name                = "ssh-key-tf-state-backend"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  public_key          = tls_private_key.this.public_key_openssh
}

##########################################################
# NETWORKING
##########################################################
resource "azurerm_virtual_network" "this" {
  name                = "vnet-tf-state-backend"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  name                 = "snet-tf-state-backend"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "this" {
  name                = "pip-tf-state-backend"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  allocation_method = "Static"
}

resource "azurerm_network_interface" "this" {
  name                = "nic-tf-state-backend"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
    primary                       = true
    subnet_id                     = azurerm_subnet.this.id
  }
}

##########################################################
# SECURITY
##########################################################
resource "azurerm_network_security_group" "this" {
  name                = "nsg-tf-state-backend"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

##########################################################
# COMPUTE
##########################################################
resource "azurerm_linux_virtual_machine" "this" {
  name                = "tf-state-backend"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  # ARM, 4 vCPUs, 8 GiB RAM, $86/month
  size = "Standard_B4pls_v2"

  computer_name  = "tf-state-backend"
  admin_username = "devblog"
  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]

  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = "devblog"
    public_key = azurerm_ssh_public_key.this.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }


  # ref: https://az-vm-image.info/?cmd=--all+--offer+fedora
  source_image_reference {
    publisher = "nuvemnestllc1695391252715"
    offer     = "id-01-fedora-41-arm64"
    sku       = "id-01-fedora-41-arm64"
    version   = "latest"
  }

  plan {
    name      = "id-01-fedora-41-arm64"
    publisher = "nuvemnestllc1695391252715"
    product   = "id-01-fedora-41-arm64"
  }

  custom_data = base64encode(file("${path.module}/cloud-init.yml"))

  lifecycle {
    ignore_changes = [
      custom_data,
    ]
  }
}

##########################################################
# Backup
##########################################################
resource "azurerm_recovery_services_vault" "this" {
  name                = "tf-state-backend-rsv"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"

  soft_delete_enabled = true
}

resource "azurerm_backup_policy_vm" "this" {
  name                = "tf-state-backend-backup-policy"
  resource_group_name = azurerm_resource_group.this.name
  recovery_vault_name = azurerm_recovery_services_vault.this.name

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 14
  }

  retention_weekly {
    count    = 4
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = 6
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }
}

resource "azurerm_backup_protected_vm" "this" {
  resource_group_name = azurerm_resource_group.this.name
  recovery_vault_name = azurerm_recovery_services_vault.this.name
  source_vm_id        = azurerm_linux_virtual_machine.this.id
  backup_policy_id    = azurerm_backup_policy_vm.this.id
}

##########################################################
# DNS
##########################################################
data "cloudflare_zone" "this" {
  filter = {
    name = "developer-friendly.blog"
  }
}

resource "cloudflare_dns_record" "this" {
  zone_id = data.cloudflare_zone.this.zone_id
  content = azurerm_public_ip.this.ip_address
  name    = "tofu.developer-friendly.blog"
  proxied = false
  ttl     = 60
  type    = "A"
}
