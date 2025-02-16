data "google_project" "current" {}

resource "google_service_account" "this" {
  account_id   = "github-actions"
  display_name = "GitHub Actions CDN Publisher"
  description  = "Service account for GitHub Actions to publish to CDN bucket"
}

resource "google_project_iam_member" "this" {
  project = data.google_project.current.id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.this.email}"
}

resource "google_service_account_iam_member" "this" {
  service_account_id = google_service_account.this.name
  role               = "roles/iam.workloadIdentityUser"
  member = format(
    "principalSet://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s/attribute.repository/%s",
    data.google_project.current.number,
    var.workload_identity_pool_id,
    var.github_repo,
  )
}

resource "google_storage_bucket_iam_binding" "this" {
  bucket = var.bucket_name
  role   = "roles/storage.objectAdmin"
  members = [
    "serviceAccount:${google_service_account.this.email}"
  ]
}
