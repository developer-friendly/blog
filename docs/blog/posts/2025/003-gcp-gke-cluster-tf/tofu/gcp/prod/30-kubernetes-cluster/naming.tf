module "naming" {
  for_each = toset([
    "gke",
    "vpc",
  ])

  source = "../../../modules/naming"

  environment   = "prod"
  resource_type = each.key
  suffix        = "k8s-cluster"
}
