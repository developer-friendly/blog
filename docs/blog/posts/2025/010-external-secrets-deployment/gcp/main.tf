data "google_project" "current" {}

resource "google_project_iam_member" "external_secrets" {
  project = data.google_project.current.project_id
  role    = "roles/secretmanager.secretAccessor"

  member = format(
    "principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/%s",
    data.google_project.current.number,
    data.google_project.current.project_id,
    "external-secrets",
    "external-secrets",
  )
}
