data "aws_iam_policy_document" "iam_policy" {
  statement {
    actions = [
      "route53:GetChange",
    ]
    resources = [
      "arn:aws:route53:::change/${var.hosted_zone_id}",
    ]
  }

  statement {
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${var.hosted_zone_id}",
    ]
  }

  statement {
    actions = [
      "route53:ListHostedZonesByName",
    ]
    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
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

data "tls_certificate" "this" {
  url = var.oidc_issuer_url
}

resource "aws_iam_openid_connect_provider" "this" {
  url = var.oidc_issuer_url

  client_id_list = [
    var.access_token_audience
  ]

  thumbprint_list = [
    data.tls_certificate.this.certificates[0].sha1_fingerprint
  ]
}

resource "aws_iam_role" "this" {
  name = var.role_name
  inline_policy {
    name   = "${var.role_name}-route53"
    policy = data.aws_iam_policy_document.iam_policy.json
  }
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}
