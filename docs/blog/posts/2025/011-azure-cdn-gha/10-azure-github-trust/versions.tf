terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "< 4"
    }
  }

  required_version = "< 2"
}
