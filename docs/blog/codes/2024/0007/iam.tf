locals {
  repository_name   = "${var.github_owner}/${var.github_repository}"
  repository_branch = "refs/heads/main"
}

data "aws_iam_policy_document" "this" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${aws_iam_openid_connect_provider.this.url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${aws_iam_openid_connect_provider.this.url}:sub"
      values   = ["repo:${local.repository_name}:ref:${local.repository_branch}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "github-actions-oidc-role"
  assume_role_policy = data.aws_iam_policy_document.this.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",
  ]
}
