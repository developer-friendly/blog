terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "< 5"
    }
    # DNS provider
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "< 6"
    }
    # SSH private key generation
    tls = {
      source  = "hashicorp/tls"
      version = "< 5"
    }
  }

  required_version = "< 2"
}
