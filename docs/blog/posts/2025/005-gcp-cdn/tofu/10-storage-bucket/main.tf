data "google_client_config" "current" {}
data "google_project" "current" {}

resource "random_pet" "this" {
  length = 6
}

resource "google_storage_bucket" "this" {
  name          = random_pet.this.id
  location      = data.google_client_config.current.region
  force_destroy = true

  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "OPTIONS"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

resource "google_storage_bucket_iam_member" "this" {
  bucket = google_storage_bucket.this.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
