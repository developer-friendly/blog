data "google_client_config" "current" {}

resource "google_kms_key_ring" "this" {
  name     = module.naming["keyring"].generated_name
  location = data.google_client_config.current.region

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key" "this" {
  name            = module.naming["cryptokey"].generated_name
  key_ring        = google_kms_key_ring.this.id
  rotation_period = format("%ss", 60 * 60 * 24 * 30) # 30 days

  lifecycle {
    # NOTE: removing the TF resource will NOT delete the key from GCP
    prevent_destroy = true
  }

  labels = {
    env = "prod"
  }
}
