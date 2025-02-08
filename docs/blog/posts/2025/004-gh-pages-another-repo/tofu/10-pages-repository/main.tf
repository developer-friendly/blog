resource "github_repository" "this" {
  name       = "deploy-pages-target"
  visibility = "public"

  auto_init = true

  pages {
    build_type = "workflow"
    source {
      branch = "main"
      path   = "/"
    }
  }

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
  content             = file("${path.module}/files/ci.yml")
  commit_message      = "chore(CI): add pages deployment workflow"
  commit_author       = "opentofu[bot]"
  commit_email        = "opentofu[bot]@users.noreply.github.com"
  overwrite_on_create = true
}

resource "github_repository_file" "index_html" {
  repository          = github_repository.this.name
  branch              = "main"
  file                = "index.html"
  content             = file("${path.module}/files/index.html")
  commit_message      = "chore: add initial index.html"
  commit_author       = "opentofu[bot]"
  commit_email        = "opentofu[bot]@users.noreply.github.com"
  overwrite_on_create = true

  depends_on = [
    github_repository_file.ci,
  ]
}

resource "tls_private_key" "deploy_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "github_repository_deploy_key" "this" {
  title      = "Pages Deployment"
  repository = github_repository.this.name
  key        = tls_private_key.deploy_key.public_key_openssh
  read_only  = false
}
