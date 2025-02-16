terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "< 7"
    }
  }

  required_version = "< 2"
}
