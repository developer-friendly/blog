data "aws_ssm_parameter" "this" {
  name = "/github/developer-friendly/blog/flux-system/receiver/token"
}


resource "github_repository_webhook" "this" {
  repository = "echo-server"

  configuration {
    url          = "https://3fd76690-8601-4894-a6e4-057f62e58551.developer-friendly.blog"
    content_type = "json"
    insecure_ssl = false
    secret       = data.aws_ssm_parameter.this.value
  }

  active = true

  events = ["push", "ping"]
}
