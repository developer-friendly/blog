terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "< 7"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "< 5"
    }
  }
  required_version = "< 2"
}
