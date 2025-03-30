inputs = {
  github_org  = "developer-friendly"
  github_repo = "deploy-frontend-to-azure-cdn"

  azure_client_id = dependency.oidc.outputs.client_id
  azure_tenant_id = dependency.oidc.outputs.tenant_id

  azure_subscription_id = dependency.cdn.outputs.subscription_id
  storage_account_name  = dependency.cdn.outputs.storage_account_name
  cdn_profile_name      = dependency.cdn.outputs.cdn_profile_name
  cdn_endpoint          = dependency.cdn.outputs.cdn_endpoint
  resource_group        = dependency.cdn.outputs.resource_group_name
}

dependency "oidc" {
  config_path = "../10-azure-github-trust"
}

dependency "cdn" {
  config_path = "../20-azure-cdn-blob"
}
