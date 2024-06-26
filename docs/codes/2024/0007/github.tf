data "aws_region" "current" {}
data "aws_caller_identity" "this" {}

resource "github_actions_variable" "this" {
  for_each = {
    AWS_REGION         = data.aws_region.current.name
    AWS_ROLE_ARN       = aws_iam_role.this.arn
    SSM_DEMO_PARAMETER = var.ssm_demo_parameter
  }

  repository    = var.github_repository
  variable_name = each.key
  value         = each.value
}

resource "github_actions_secret" "this" {
  repository      = var.github_repository
  secret_name     = "AWS_ACCOUNT_ID"
  plaintext_value = data.aws_caller_identity.this.account_id
}
