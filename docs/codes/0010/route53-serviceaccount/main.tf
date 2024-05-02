data "terraform_remote_state" "iam_role" {
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

resource "kubernetes_annotations" "this" {
  api_version = "v1"
  kind        = "ServiceAccount"
  metadata {
    name      = data.terraform_remote_state.iam_role.outputs.service_account_name
    namespace = data.terraform_remote_state.iam_role.outputs.service_account_namespace
  }
  annotations = {
    "eks.amazonaws.com/audience" : data.terraform_remote_state.iam_role.outputs.access_token_audience
    "eks.amazonaws.com/role-arn" : data.terraform_remote_state.iam_role.outputs.iam_role_arn
  }

  field_manager = var.field_manager
}

resource "kubernetes_manifest" "cluster_issuer" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "aws-route53"
    }
    "spec" = {
      "acme" = {
        "email"                 = "admin@developer-friendly.blog"
        "enableDurationFeature" = true
        "privateKeySecretRef" = {
          "name" = "letsencrypt"
        }
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "solvers" = [
          {
            "dns01" = {
              "route53" = {
                "hostedZoneID" = data.terraform_remote_state.hosted_zone.outputs.hosted_zone_id
                "region"       = "eu-central-1"
              }
            }
          }
        ]
      }
    }
  }
}
