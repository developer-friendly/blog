terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "< 7"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "< 6"
    }
  }
  required_version = "< 2"
}
