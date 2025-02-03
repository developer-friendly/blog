include "backend" {
  path = find_in_parent_folders("backend.hcl")
}

include "gcp" {
  path = find_in_parent_folders("gcp.hcl")
}

inputs = {
  network_name    = dependency.networking.outputs.network_name
  subnetwork_name = dependency.networking.outputs.subnetwork_name

  kms_key_id = dependency.kms_key.outputs.crypto_key_id
}

dependency "kms_key" {
  config_path = "../gke-encryption-key"
}

dependency "networking" {
  config_path = "../networking"
}
