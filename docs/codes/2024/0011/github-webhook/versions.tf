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
  }
  required_version = "< 2"
}

provider "github" {
  owner = var.github_owner
}
