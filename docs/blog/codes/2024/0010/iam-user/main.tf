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

resource "aws_iam_user" "this" {
  name = var.user_name
}

resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
}

resource "aws_ssm_parameter" "access_key" {
  for_each = {
    "/cert-manager/access-key" = aws_iam_access_key.this.id
    "/cert-manager/secret-key" = aws_iam_access_key.this.secret
  }

  name  = each.key
  type  = "SecureString"
  value = each.value
}
