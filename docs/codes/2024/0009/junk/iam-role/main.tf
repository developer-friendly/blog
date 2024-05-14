resource "aws_iam_role" "this" {
  name = var.iam_role_name
  assume_role_policy = jsonencode({
    "Statement" : [
      {
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "${aws_iam_openid_connect_provider.this.arn}"
        },
        "Condition" : {
          "StringEquals" : {
            "${aws_iam_openid_connect_provider.this.url}:aud" : "${var.access_token_audience}",
            "${aws_iam_openid_connect_provider.this.url}:sub" : "system:serviceaccount:${var.service_account_namespace}:${var.service_account_name}"
          }
        }
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMFullAccess",
  ]
}
