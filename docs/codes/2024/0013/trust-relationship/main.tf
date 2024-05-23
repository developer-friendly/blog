locals {
  tenant_url = format("https://sts.windows.net/%s/", data.azuread_client_config.current.tenant_id)
}

data "azuread_client_config" "current" {}

data "tls_certificate" "this" {
  url = local.tenant_url
}

resource "aws_iam_openid_connect_provider" "this" {
  url            = local.tenant_url
  client_id_list = ["https://management.core.windows.net/"]
  thumbprint_list = [
    data.tls_certificate.this.certificates.0.sha1_fingerprint
  ]
}

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${aws_iam_openid_connect_provider.this.url}:sub"
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
