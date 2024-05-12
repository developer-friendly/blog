####################
# Deploy key
####################
resource "tls_private_key" "this" {
  algorithm = var.tls_private_key_algorithm
}

resource "github_repository_deploy_key" "this" {
  repository = var.github_repository_name
  title      = "Developer Friendly Bot"
  key        = tls_private_key.this.public_key_openssh
  read_only  = false
}

resource "aws_ssm_parameter" "deploy_key" {
  name  = var.deploy_key_ssm_name
  type  = "SecureString"
  value = tls_private_key.this.private_key_pem
}

####################
# GHCR Secret
####################
resource "aws_ssm_parameter" "ghcr_token" {
  name  = var.ghcr_token_aws_ssm_name
  type  = "SecureString"
  value = var.github_pat
}


####################
# GPG key
####################
resource "gpg_private_key" "this" {
  name       = var.gpg_key_name
  email      = var.gpg_key_email
  passphrase = var.gpg_key_passphrase
  rsa_bits   = var.gpg_key_rsa_bits
}

resource "github_user_gpg_key" "this" {
  provider = github.individual

  armored_public_key = gpg_private_key.this.public_key
}

resource "aws_ssm_parameter" "gpg_key" {
  name  = var.gpg_key_aws_ssm_name
  type  = "SecureString"
  value = gpg_private_key.this.private_key
}
