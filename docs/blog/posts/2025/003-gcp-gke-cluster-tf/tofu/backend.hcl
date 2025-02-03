locals {
  workspace = replace(path_relative_to_include(), "/", "-")
  # e.g. gcp-prod-10-networking
}

generate "remote_state" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      backend "remote" {
        hostname     = "app.terraform.io"
        organization = "developer-friendly-blog"
        workspaces {
          name = "${local.workspace}"
        }
      }
    }
  EOF
}
