resource "azurerm_subnet" "this" {
  # The following name has to be exactly as you see here!
  name                 = "AzureBastionSubnet"
  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = data.azurerm_virtual_network.this.name
  address_prefixes     = [local.subnet_cidr]
}

resource "azurerm_public_ip" "this" {
  name                = module.naming.public_ip.name_unique
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "this" {
  name                = module.naming.bastion_host.name_unique
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  # Native Client i.e. ssh from the command line
  tunneling_enabled = true

  # Native Client requires at least `Standard` SKU
  sku = "Standard"


  ip_configuration {
    name                 = module.naming.firewall_ip_configuration.name_unique
    subnet_id            = azurerm_subnet.this.id
    public_ip_address_id = azurerm_public_ip.this.id
  }
}
