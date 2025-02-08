output "repository_full_name" {
  value = github_repository.this.full_name
}

output "deploy_private_key" {
  value     = tls_private_key.deploy_key.private_key_pem
  sensitive = true
}
