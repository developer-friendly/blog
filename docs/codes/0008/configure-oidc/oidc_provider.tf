data "tls_certificate" "this" {
  url = "https://${data.terraform_remote_state.k8s.outputs.oidc_provider_url}"
}

resource "aws_iam_openid_connect_provider" "this" {
  url = "https://${data.terraform_remote_state.k8s.outputs.oidc_provider_url}"

  # audience
  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.this.certificates[0].sha1_fingerprint
  ]
}
