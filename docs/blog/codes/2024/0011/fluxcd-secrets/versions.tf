terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.2"
    }
    gpg = {
      source  = "Olivr/gpg"
      version = "~> 0.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  required_version = "< 2"
}

provider "github" {
  owner = var.github_owner
}

provider "github" {
  alias = "individual"

  owner = var.github_owner_individual
}
