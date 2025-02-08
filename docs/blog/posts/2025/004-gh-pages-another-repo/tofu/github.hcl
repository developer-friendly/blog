generate "github" {
  path      = "provider_github.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "github" {
      owner = "developer-friendly"
    }
  EOF
}
