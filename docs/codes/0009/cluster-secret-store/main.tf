data "terraform_remote_state" "k8s" {
  backend = "local"

  config = {
    path = "../aws-oidc/terraform.tfstate"
  }
}

resource "kubernetes_annotations" "this" {
  api_version = "v1"
  kind        = "ServiceAccount"
  metadata {
    name      = data.terraform_remote_state.k8s.outputs.service_account_name
    namespace = data.terraform_remote_state.k8s.outputs.service_account_namespace
  }
  annotations = {
    "eks.amazonaws.com/audience" : data.terraform_remote_state.k8s.outputs.access_token_audience
    "eks.amazonaws.com/role-arn" : data.terraform_remote_state.k8s.outputs.iam_role_arn
  }

  field_manager = var.field_manager
}

resource "kubernetes_manifest" "this" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = var.cluster_secret_store_name
    }
    spec = {
      provider = {
        aws = {
          region  = var.aws_region
          service = "ParameterStore"
          auth = {
            jwt = {
              serviceAccountRef = {
                name      = data.terraform_remote_state.k8s.outputs.service_account_name
                namespace = data.terraform_remote_state.k8s.outputs.service_account_namespace
              }
            }
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_annotations.this
  ]
}
