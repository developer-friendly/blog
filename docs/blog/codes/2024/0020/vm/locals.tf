locals {
  vnet_cidr   = data.azurerm_virtual_network.this.address_space[0]
  subnet_cidr = (cidrsubnets(local.vnet_cidr, 8, 8, 8))[2]
}
