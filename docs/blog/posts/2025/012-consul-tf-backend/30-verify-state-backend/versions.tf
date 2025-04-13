terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "< 4"
    }
  }

  required_version = "< 2"
}
