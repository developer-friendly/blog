terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "< 5"
    }
  }

  required_version = "< 2"
}
