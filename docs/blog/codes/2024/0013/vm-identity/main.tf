locals {
  oidc_arn = data.terraform_remote_state.trust_relationship.outputs.oidc_arn
  oidc_url = data.terraform_remote_state.trust_relationship.outputs.oidc_url
}

data "terraform_remote_state" "trust_relationship" {
  backend = "local"

  config = {
    path = "../trust-relationship/terraform.tfstate"
  }
}

resource "azurerm_resource_group" "this" {
  name     = "aws-oidc-rg"
  location = "Germany West Central"
}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = "aws-oidc-identity"
  resource_group_name = azurerm_resource_group.this.name
}

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [local.oidc_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:sub"
      values   = [azurerm_user_assigned_identity.this.principal_id]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.trust.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
  ]
}

# Enable later ansible-playbook to fetch this value from remote API call
resource "aws_ssm_parameter" "role_arn" {
  name  = "/azure/oidc/role-arn"
  type  = "String"
  value = aws_iam_role.this.arn
}
