include "gcp" {
  path = find_in_parent_folders("gcp.hcl")
}

inputs = {
  bucket_name               = dependency.gcs.outputs.bucket_name
  workload_identity_pool_id = dependency.github_workload_identity.outputs.workload_identity_pool_id
}

dependency "gcs" {
  config_path = "../10-storage-bucket"
}

dependency "github_workload_identity" {
  config_path = "../20-github-workload-identity"
}
