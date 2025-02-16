include "github" {
  path = find_in_parent_folders("github.hcl")
}

inputs = {
  google_storage_bucket              = dependency.gcs.outputs.bucket_name
  workload_identity_pool_provider_id = dependency.github_workload_identity.outputs.workload_identity_pool_provider_id
  google_service_account_email       = dependency.github_actions_iam.outputs.service_account_email
}

dependency "gcs" {
  config_path = "../10-storage-bucket"
}

dependency "github_workload_identity" {
  config_path = "../20-github-workload-identity"
}

dependency "github_actions_iam" {
  config_path = "../30-github-actions-iam"
}
