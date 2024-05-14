output "github_deploy_key" {
  value = {
    id         = github_repository_deploy_key.this.id
    title      = github_repository_deploy_key.this.title
    repository = github_repository_deploy_key.this.repository
  }
}

output "ssm_name" {
  value = {
    ghcr_token = aws_ssm_parameter.ghcr_token.name
    deploy_key = aws_ssm_parameter.deploy_key.name
    gpg_key    = aws_ssm_parameter.gpg_key.name
  }
}
