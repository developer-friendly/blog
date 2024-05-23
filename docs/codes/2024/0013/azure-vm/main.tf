data "terraform_remote_state" "trust_relationship" {
  backend = "local"

  config = {
    path = "../trust-relationship/terraform.tfstate"
  }
}

locals {
  identity_id = data.terraform_remote_state.trust_relationship.outputs.user_assigned_identity_id
}


data "azurerm_resource_group" "this" {
  name     = "aws-oidc-rg"
}
