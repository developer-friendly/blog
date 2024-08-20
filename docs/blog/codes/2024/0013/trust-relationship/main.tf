locals {
  tenant_id  = coalesce(var.tenant_id, data.azuread_client_config.current.tenant_id)
  tenant_url = format("https://sts.windows.net/%s/", local.tenant_id)
}

data "azuread_client_config" "current" {}

data "tls_certificate" "this" {
  url = local.tenant_url
}

resource "aws_iam_openid_connect_provider" "this" {
  url = local.tenant_url

  # aka: `aud` claim
  client_id_list = ["https://management.core.windows.net/"]

  thumbprint_list = [
    data.tls_certificate.this.certificates.0.sha1_fingerprint
  ]
}
