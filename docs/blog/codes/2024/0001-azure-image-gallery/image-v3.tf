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

resource "azurerm_image" "example" {
  name                      = "exampleimage"
  location                  = azurerm_linux_virtual_machine.example.location
  resource_group_name       = azurerm_linux_virtual_machine.example.name
  source_virtual_machine_id = azurerm_linux_virtual_machine.example.id
}

resource "azurerm_shared_image_version" "example" {
  name                = "0.0.1"
  gallery_name        = azurerm_shared_image.example.gallery_name
  image_name          = azurerm_shared_image.example.name
  resource_group_name = azurerm_shared_image.example.resource_group_name
  location            = azurerm_shared_image.example.location
  managed_image_id    = azurerm_image.example.id

  target_region {
    name                   = azurerm_shared_image.example.location
    regional_replica_count = 5
    storage_account_type   = "Standard_LRS"
  }
}
