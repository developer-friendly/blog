terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.104"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
  }
  required_version = "< 2"
}

provider "azurerm" {
  features {}
}
