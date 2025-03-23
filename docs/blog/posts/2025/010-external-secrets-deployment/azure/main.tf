data "azurerm_subscription" "current" {}

data "azurerm_kubernetes_cluster" "this" {
  name                = "my-aks-cluster"
  resource_group_name = "my-resource-group"
}

resource "azurerm_user_assigned_identity" "this" {
  name                = "vault-external-secrets"
  resource_group_name = "my-resource-group"
  location            = "Germany West Central"
}

resource "azurerm_federated_identity_credential" "this" {
  name                = "external-secrets"
  resource_group_name = "my-resource-group"
  audience            = ["api://AzureADTokenExchange"]
  issuer              = data.azurerm_kubernetes_cluster.this.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.this.id
  subject             = "system:serviceaccount:external-secrets:external-secrets"
}

resource "azurerm_key_vault_access_policy" "this" {
  key_vault_id = var.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.this.principal_id

  secret_permissions = [
    "Get",
  ]

  certificate_permissions = [
    "Get",
  ]
}
