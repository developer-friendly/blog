terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "< 6"
    }
  }
  required_version = "< 2"
}
