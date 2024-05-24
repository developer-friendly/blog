data "terraform_remote_state" "vm_identity" {
  backend = "local"

  config = {
    path = "../vm-identity/terraform.tfstate"
  }
}

locals {
  identity_id         = data.terraform_remote_state.vm_identity.outputs.identity_id
  resource_group_name = data.terraform_remote_state.vm_identity.outputs.resource_group_name
  location            = data.terraform_remote_state.vm_identity.outputs.location
  role_arn            = data.terraform_remote_state.vm_identity.outputs.role_arn
}
