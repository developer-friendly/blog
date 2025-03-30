terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "< 5"
    }
    random = {
      source  = "hashicorp/random"
      version = "< 4"
    }
  }

  required_version = "< 2"
}
