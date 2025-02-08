resource "github_repository" "this" {
  name       = "deploy-pages-source"
  visibility = "public"

  auto_init = true

  lifecycle {
    ignore_changes = [
      vulnerability_alerts,
    ]
  }
}

resource "github_repository_file" "ci" {
  repository          = github_repository.this.name
  branch              = "main"
  file                = ".github/workflows/ci.yml"
  content             = templatefile("${path.module}/files/ci.yml.tftpl", {
    repository_full_name = var.pages_repository_full_name
  })
  commit_message      = <<-EOF
    chore(CI): add build workflow

    [skip ci]
  EOF
  commit_author       = "opentofu[bot]"
  commit_email        = "opentofu[bot]@users.noreply.github.com"
  overwrite_on_create = true
}

resource "github_actions_secret" "deploy_key" {
  repository       = github_repository.this.name
  secret_name      = "GH_PAGES_SSH_PRIVATE_KEY"
  plaintext_value  = var.pages_deploy_private_key
}
