data "terraform_remote_state" "iam_role" {
  count = var.role_arn != null ? 0 : 1

  backend = "local"

  config = {
    path = "../route53-iam-role/terraform.tfstate"
  }
}

data "terraform_remote_state" "hosted_zone" {
  backend = "local"

  config = {
    path = "../hosted-zone/terraform.tfstate"
  }
}

locals {
  sa_audience = coalesce(var.access_token_audience, data.terraform_remote_state.iam_role[0].outputs.access_token_audience)
  sa_role_arn = coalesce(var.role_arn, data.terraform_remote_state.iam_role[0].outputs.iam_role_arn)
}

resource "helm_release" "cert_manager" {
  name       = var.release_name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.release_version
  namespace  = var.release_namespace

  reuse_values = true

  values = [
    templatefile("${path.module}/values.yml.tftpl", {
      sa_audience = local.sa_audience,
      sa_role_arn = local.sa_role_arn
    })
  ]
}

resource "kubernetes_manifest" "cluster_issuer" {
  manifest = yamldecode(<<-EOF
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: route53-issuer
    spec:
      acme:
        email: admin@developer-friendly.blog
        enableDurationFeature: true
        privateKeySecretRef:
          name: route53-issuer
        server: https://acme-v02.api.letsencrypt.org/directory
        solvers:
        - dns01:
            route53:
              hostedZoneID: ${data.terraform_remote_state.hosted_zone.outputs.hosted_zone_id}
              region: eu-central-1
  EOF
  )
}
