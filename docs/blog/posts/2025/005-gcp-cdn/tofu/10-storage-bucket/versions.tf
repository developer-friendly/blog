terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "< 7"
    }
    random = {
      source  = "hashicorp/random"
      version = "< 4"
    }
  }

  required_version = "< 2"
}
