terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "< 7"
    }
    http = {
      source  = "hashicorp/http"
      version = "< 4"
    }
  }

  required_version = "< 2"
}
