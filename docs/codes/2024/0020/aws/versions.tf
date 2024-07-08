terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.57"
    }
  }

  required_version = "< 2"
}
