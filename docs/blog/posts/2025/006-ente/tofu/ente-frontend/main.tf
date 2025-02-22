resource "github_repository" "this" {
  for_each = toset([
    "accounts",
    "photos",
    "auth",
    "cast",
  ])

  name = format("ente-%s", each.key)

  visibility = "public"

  vulnerability_alerts = true

  auto_init = true

  pages {
    build_type = "workflow"
    source {
      branch = "main"
      path   = "/"
    }

    # `cname` is only applied after the initial repo creation
    # you'll need to `tofu apply` this stack twice! :(
    cname = format("%s.developer-friendly.blog", each.key)
  }
}

resource "github_repository_file" "ci" {
  for_each = github_repository.this

  repository = each.value.name
  branch     = "main"
  file       = ".github/workflows/ci.yml"
  content = templatefile("${path.module}/files/ci.yml.tftpl", {
    build_target = each.key
  })
  commit_message      = "chore(CI): add pages deployment workflow"
  commit_author       = "opentofu[bot]"
  commit_email        = "opentofu[bot]@users.noreply.github.com"
  overwrite_on_create = true
}
