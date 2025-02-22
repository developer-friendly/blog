provider "github" {
  owner = "developer-friendly"
}

resource "github_repository" "this" {
  name = "ente-docker"

  visibility = "public"

  vulnerability_alerts = true

  auto_init = true
}

resource "github_repository_file" "ci" {
  repository          = github_repository.this.name
  branch              = "main"
  file                = ".github/workflows/ci.yml"
  content             = file("${path.module}/files/ci.yml")
  commit_message      = "chore(CI): add workflow"
  commit_author       = "opentofu[bot]"
  commit_email        = "opentofu[bot]@users.noreply.github.com"
  overwrite_on_create = true
}
