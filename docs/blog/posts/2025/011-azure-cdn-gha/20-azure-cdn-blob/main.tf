data "azurerm_client_config" "current" {}

resource "random_pet" "this" {
  for_each = toset([
    "storage_account",
    "cdn_profile",
    "cdn_endpoint",
  ])

  length = 3
}

resource "azurerm_resource_group" "this" {
  name     = "deploy-static-site-to-az"
  location = "Germany West Central"
}

resource "azurerm_storage_account" "this" {
  name                     = replace(random_pet.this["storage_account"].id, "-", "")
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
}

resource "azurerm_storage_account_static_website" "this" {
  storage_account_id = azurerm_storage_account.this.id
  error_404_document = "index.html"
  index_document     = "index.html"
}

resource "azurerm_cdn_profile" "this" {
  name                = random_pet.this["cdn_profile"].id
  location            = "global"
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "this" {
  name                = random_pet.this["cdn_endpoint"].id
  profile_name        = azurerm_cdn_profile.this.name
  location            = "global"
  resource_group_name = azurerm_resource_group.this.name
  origin_host_header  = azurerm_storage_account.this.primary_web_host

  origin {
    name      = "azblob"
    host_name = azurerm_storage_account.this.primary_web_host
  }

  delivery_rule {
    name  = "EnforceHTTPS"
    order = 1

    request_scheme_condition {
      operator     = "Equal"
      match_values = ["HTTP"]
    }

    url_redirect_action {
      redirect_type = "PermanentRedirect"
      protocol      = "Https"
    }
  }
}

resource "azurerm_role_assignment" "blob_contributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.service_principal_guid
}

resource "azurerm_role_assignment" "endpoint_contributor" {
  scope                = azurerm_cdn_endpoint.this.id
  role_definition_name = "CDN Endpoint Contributor"
  principal_id         = var.service_principal_guid
}
