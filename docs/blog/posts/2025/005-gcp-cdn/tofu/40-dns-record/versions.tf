terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "< 7"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "< 6"
    }
  }

  required_version = "< 2"
}
