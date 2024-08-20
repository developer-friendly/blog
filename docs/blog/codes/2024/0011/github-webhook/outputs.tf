output "webhook_config" {
  value = {
    repository = github_repository_webhook.this.repository
    url        = github_repository_webhook.this.url
  }
}
