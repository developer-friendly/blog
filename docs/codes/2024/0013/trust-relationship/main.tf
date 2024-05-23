data "azuread_client_config" "current" {}

locals {
  tenant_url = format("https://sts.windows.net/%s/", data.azuread_client_config.current.tenant_id)
}

data "tls_certificate" "this" {
  url = local.tenant_url
}

resource "aws_iam_openid_connect_provider" "this" {
  url            = local.tenant_url
  client_id_list = ["https://management.azure.com/"]
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
      variable = "${aws_iam_openid_connect_provider.this.url}:iss"
      values   = [local.tenant_url]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.trust.json
}
