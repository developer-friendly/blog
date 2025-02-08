include "github" {
  path = find_in_parent_folders("github.hcl")
}

inputs = {
  pages_repository_full_name = dependency.pages_repo.outputs.repository_full_name
  pages_deploy_private_key   = dependency.pages_repo.outputs.deploy_private_key
}

dependency "pages_repo" {
  config_path = "../10-pages-repository"
}
