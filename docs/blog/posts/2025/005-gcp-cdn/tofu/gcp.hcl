generate "gcp" {
  path      = "provider_gcp.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "google" {
      project = "developer-friendly"
      region  = "europe-west4"
    }
  EOF
}
