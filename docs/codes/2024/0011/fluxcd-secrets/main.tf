####################
# Deploy key
####################
resource "tls_private_key" "this" {
  algorithm = "ED25519"
}

resource "github_repository_deploy_key" "this" {
  repository = "echo-server"
  title      = "Developer Friendly Bot"
  key        = tls_private_key.this.public_key_openssh
  read_only  = false
}

resource "aws_ssm_parameter" "deploy_key" {
  name  = "/github/echo-server/deploy-key"
  type  = "SecureString"
  value = tls_private_key.this.private_key_pem
}

####################
# GHCR Secret
####################
resource "aws_ssm_parameter" "ghcr_token" {
  name  = "/github/echo-server/ghcr-token"
  type  = "SecureString"
  value = var.github_pat
}


####################
# GPG key
####################
resource "gpg_private_key" "this" {
  name       = "Developer Friendly Bot"
  email      = "github@developer-friendly.blog"
  passphrase = var.gpg_key_passphrase
  rsa_bits   = 2048
}

resource "github_user_gpg_key" "this" {
  provider = github.individual

  armored_public_key = gpg_private_key.this.public_key
}

resource "aws_ssm_parameter" "gpg_key" {
  name  = "/github/gpg-keys/developer-friendly-bot"
  type  = "SecureString"
  value = gpg_private_key.this.private_key
}
