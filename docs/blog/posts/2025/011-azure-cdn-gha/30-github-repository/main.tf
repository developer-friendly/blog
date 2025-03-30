data "github_repository" "this" {
  name = var.github_repo
}

resource "github_actions_secret" "this" {
  for_each = {
    AZURE_CLIENT_ID       = var.azure_client_id
    AZURE_SUBSCRIPTION_ID = var.azure_subscription_id
    AZURE_TENANT_ID       = var.azure_tenant_id
    CDN_ENDPOINT          = var.cdn_endpoint
    CDN_PROFILE_NAME      = var.cdn_profile_name
    RESOURCE_GROUP        = var.resource_group
    STORAGE_ACCOUNT_NAME  = var.storage_account_name
  }

  repository      = data.github_repository.this.name
  secret_name     = each.key
  plaintext_value = each.value
}

resource "github_repository_file" "ci" {
  repository          = data.github_repository.this.name
  branch              = "main"
  file                = ".github/workflows/ci.yml"
  content             = file("${path.module}/files/ci.yml")
  commit_message      = "chore(CI): add github workflow"
  commit_author       = "opentofu[bot]"
  commit_email        = "opentofu[bot]@users.noreply.github.com"
  overwrite_on_create = true

  depends_on = [
    github_actions_secret.this,
  ]
}
