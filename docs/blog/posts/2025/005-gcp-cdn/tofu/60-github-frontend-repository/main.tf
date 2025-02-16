resource "github_repository" "this" {
  name = "frontend-in-gcp-bucket"

  visibility = "public"

  vulnerability_alerts = true

  auto_init = true
}

resource "github_repository_file" "asset" {
  for_each = toset([
    "index.html",
    "index.js",
    "package.json",
  ])

  repository          = github_repository.this.name
  branch              = "main"
  file                = each.key
  content             = file("${path.module}/files/${each.key}")
  commit_message      = "chore: add asset ${each.key}"
  commit_author       = "opentofu[bot]"
  commit_email        = "opentofu[bot]@users.noreply.github.com"
  overwrite_on_create = true
}

resource "github_repository_file" "ci" {
  repository = github_repository.this.name
  branch     = "main"
  file       = ".github/workflows/ci.yml"
  content = templatefile("${path.module}/files/ci.yml.tftpl", {
    google_storage_bucket              = var.google_storage_bucket
    workload_identity_pool_provider_id = var.workload_identity_pool_provider_id
    google_service_account_email       = var.google_service_account_email
  })
  commit_message      = "chore(CI): add pages deployment workflow"
  commit_author       = "opentofu[bot]"
  commit_email        = "opentofu[bot]@users.noreply.github.com"
  overwrite_on_create = true

  depends_on = [
    github_repository_file.asset,
  ]
}
