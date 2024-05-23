resource "azurerm_resource_group" "this" {
  name     = "aws-oidc-rg"
  location = "Germany West Central"
}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = "aws-oidc-identity"
  resource_group_name = azurerm_resource_group.this.name
}
