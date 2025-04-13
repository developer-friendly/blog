terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "< 5"
    }
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = "< 1"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "< 6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "< 5"
    }
  }

  required_version = "< 2"
}
