data "terraform_remote_state" "k8s" {
  count = var.oidc_issuer_url != null ? 0 : 1

  backend = "local"

  config = {
    path = "../k8s/terraform.tfstate"
  }
}

locals {
  oidc_issuer_url = try(var.oidc_issuer_url, data.terraform_remote_state.k8s[0].outputs.oidc_provider_url)
}

data "tls_certificate" "this" {
  url = local.oidc_issuer_url
}

resource "aws_iam_openid_connect_provider" "this" {
  url = local.oidc_issuer_url

  client_id_list = [
    var.access_token_audience
  ]

  thumbprint_list = [
    data.tls_certificate.this.certificates[0].sha1_fingerprint
  ]
}

data "aws_iam_policy_document" "this" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    effect = "Allow"

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.this.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${aws_iam_openid_connect_provider.this.url}:aud"

      values = [
        var.access_token_audience
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${aws_iam_openid_connect_provider.this.url}:sub"

      values = [
        "system:serviceaccount:${var.service_account_namespace}:${var.service_account_name}",
      ]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.this.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMFullAccess",
  ]
}
