resource "random_pet" "admin_username" {
  length    = 1

  keepers = {
    # regenerate if the VM has been recreated
    vm_name = module.naming.virtual_machine.name_unique
  }
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
}

resource "azurerm_subnet" "this" {
  name                 = module.naming.subnet.name_unique
  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = data.azurerm_virtual_network.this.name
  address_prefixes     = [local.subnet_cidr]
}

resource "azurerm_network_interface" "this" {
  name                = module.naming.network_interface.name_unique
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  ip_configuration {
    name                          = module.naming.firewall_ip_configuration.name_unique
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_ssh_public_key" "this" {
  name                = "vm-ssh-key"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  public_key          = tls_private_key.this.public_key_openssh
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = module.naming.virtual_machine.name_unique
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  size                = "Standard_B2pts_v2" # 2 ARM vCPUs, 1 GiB memory
  admin_username      = random_pet.admin_username.id
  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]

  admin_ssh_key {
    username   = random_pet.admin_username.id
    public_key = azurerm_ssh_public_key.this.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_id = "/communityGalleries/rocky-dc1c6aa6-905b-4d9c-9577-63ccc28c482a/images/Rocky-9-aarch64/versions/9.4.20240509"
}
