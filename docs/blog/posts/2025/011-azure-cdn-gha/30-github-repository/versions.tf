terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "< 7"
    }
  }

  required_version = "< 2"
}
