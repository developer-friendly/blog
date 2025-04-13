generate "azurerm" {
  path      = "provider_azurerm.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "azurerm" {
      features {}
    }
  EOF
}
