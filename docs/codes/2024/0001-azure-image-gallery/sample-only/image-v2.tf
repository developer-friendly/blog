resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "West Europe"
}

resource "azurerm_shared_image_gallery" "example" {
  name                = "example_image_gallery"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  description         = "Shared images and things."

  tags = {
    Hello = "There"
    World = "Example"
  }
}

resource "azurerm_shared_image" "example" {
  name                = "my-image"
  gallery_name        = azurerm_shared_image_gallery.example.name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  os_type             = "Linux"

  identifier {
    publisher = "PublisherName"
    offer     = "OfferName"
    sku       = "ExampleSku"
  }
}

resource "azurerm_shared_image_version" "example" {
  name                = "0.0.1"
  gallery_name        = azurerm_shared_image.example.gallery_name
  image_name          = azurerm_shared_image.example.name
  resource_group_name = azurerm_shared_image.example.resource_group_name
  location            = azurerm_shared_image.example.location

  target_region {
    name                   = azurerm_shared_image.example.location
    regional_replica_count = 1
    storage_account_type   = "Standard_LRS"
  }
}
