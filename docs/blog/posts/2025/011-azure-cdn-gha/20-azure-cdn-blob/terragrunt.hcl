generate "azure" {
  path      = "provider_azurerm.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "azurerm" {
      features {}
    }
  EOF
}

inputs = {
  service_principal_guid = dependency.oidc.outputs.service_principal_guid
}

dependency "oidc" {
  config_path = "../10-azure-github-trust"
}
