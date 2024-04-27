data "terraform_remote_state" "k8s" {
  backend = "local"

  config = {
    path = "../aws-oidc/terraform.tfstate"
  }
}
resource "kubernetes_manifest" "cluster_secret_store" {
  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind"       = "ClusterSecretStore"
    "metadata" = {
      "name" = var.cluster_secret_store_name
    }
    "spec" = {
      "provider" = {
        "aws" = {
          "region"  = var.aws_region
          "role"    = data.terraform_remote_state.k8s.outputs.iam_role_arn
          "service" = "ParameterStore"
        }
      }
    }
  }
}
