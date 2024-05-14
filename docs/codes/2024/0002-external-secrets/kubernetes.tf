resource "kubernetes_secret" "this" {
  metadata {
    name      = var.secret_name
    namespace = var.secret_namespace
  }

  binary_data = {
    AWS_ACCESS_KEY_ID     = base64encode(aws_iam_access_key.this.id)
    AWS_SECRET_ACCESS_KEY = base64encode(aws_iam_access_key.this.secret)
  }

  type = "Opaque"
}

resource "kubernetes_manifest" "this" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"

    metadata = {
      name = var.external_secret_name
    }

    spec = {
      provider = {
        aws = {
          region  = data.aws_region.current.name
          role    = aws_iam_role.this.arn
          service = "ParameterStore"

          auth = {
            secretRef = {
              accessKeyIDSecretRef = {
                key       = "AWS_ACCESS_KEY_ID"
                name      = var.secret_name
                namespace = var.secret_namespace
              }
              secretAccessKeySecretRef = {
                key       = "AWS_SECRET_ACCESS_KEY"
                name      = var.secret_name
                namespace = var.secret_namespace
              }
            }
          }
        }
      }
    }
  }
}
