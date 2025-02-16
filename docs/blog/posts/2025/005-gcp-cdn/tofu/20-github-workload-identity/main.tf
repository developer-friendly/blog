resource "google_iam_workload_identity_pool" "this" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions"
  description               = "Identity pool for GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "this" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.this.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Actions"
  description                        = "OIDC identity pool provider for GitHub Actions"

  attribute_mapping = {
    "attribute.actor"            = "assertion.actor"
    "attribute.aud"              = "assertion.aud"
    "attribute.event_name"       = "assertion.event_name"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.repository"       = "assertion.repository"
    "attribute.run_id"           = "assertion.run_id"
    "attribute.run_number"       = "assertion.run_number"
    "attribute.workflow"         = "assertion.workflow"
    "google.subject"             = "assertion.sub"
  }

  attribute_condition = <<-EOT
    attribute.repository_owner == "developer-friendly"
  EOT

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}
