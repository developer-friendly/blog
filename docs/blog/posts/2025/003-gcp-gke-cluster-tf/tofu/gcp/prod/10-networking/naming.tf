module "naming" {
  for_each = toset([
    "vpc",
    "subnet",
    "router",
    "nat",
    "firewall",
  ])

  source = "../../../modules/naming"

  environment   = "prod"
  resource_type = each.key
  suffix        = "networking"
}
