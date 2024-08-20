data "http" "admin_public_ip" {
  url = "https://checkip.amazonaws.com"
}

resource "azurerm_virtual_network" "this" {
  name                = "oidc-vnet"
  address_space       = ["100.0.0.0/16"]
  location            = local.location
  resource_group_name = local.resource_group_name
}

resource "azurerm_subnet" "this" {
  name                 = "oidc-subnet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["100.0.2.0/24"]
}

resource "azurerm_public_ip" "this" {
  name                = "oidc-pip"
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = "Static"
  ip_version          = "IPv4"
}

resource "azurerm_network_interface" "this" {
  name                = "oidc-nic"
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "ipv4"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

resource "azurerm_network_security_group" "this" {
  name                = "oidc-nsg"
  location            = local.location
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "admin"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = [
      trimspace(data.http.admin_public_ip.response_body),
    ]
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}
