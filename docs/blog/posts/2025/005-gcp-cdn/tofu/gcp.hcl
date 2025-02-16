generate "gcp" {
  path      = "provider_gcp.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "google" {
      project = "ethereal-tract-447314-n9"
      region  = "europe-west4"
    }
  EOF
}
