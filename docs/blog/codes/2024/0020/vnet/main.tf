resource "azurerm_resource_group" "this" {
  name     = module.naming.resource_group.name_unique
  location = "Germany West Central"
}

resource "azurerm_virtual_network" "this" {
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  address_space       = ["10.0.0.0/8"]
}
