module "naming" {
  for_each = toset([
    "keyring",
    "cryptokey",
  ])

  source = "../../../modules/naming"

  environment   = "prod"
  resource_type = each.key
  suffix        = "encryption-key"
}
