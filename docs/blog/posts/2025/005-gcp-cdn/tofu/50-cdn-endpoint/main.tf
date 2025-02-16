###############################################################################
# CDN Backend
###############################################################################
resource "google_compute_backend_bucket" "this" {
  name        = "cdn-backend-bucket"
  bucket_name = var.bucket_name
  enable_cdn  = true

  cdn_policy {
    cache_mode  = "CACHE_ALL_STATIC"
    client_ttl  = 3600
    default_ttl = 3600
    max_ttl     = 86400
  }
}

###############################################################################
# HTTP Traffic (port 80)
###############################################################################
resource "google_compute_url_map" "https_redirect" {
  name            = "cdn-url-map-https-redirect"

  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

resource "google_compute_target_http_proxy" "this" {
  name    = "cdn-http-proxy"
  url_map = google_compute_url_map.https_redirect.self_link
}

resource "google_compute_global_forwarding_rule" "http" {
  for_each = var.public_ip_address

  name       = lower(format("%s-%s", "cdn-http-rule", each.key))
  target     = google_compute_target_http_proxy.this.self_link
  port_range = "80"
  ip_address = each.value
}

###############################################################################
# HTTPS Traffic (port 443)
###############################################################################
resource "google_compute_url_map" "this" {
  name            = "cdn-url-map"
  default_service = google_compute_backend_bucket.this.self_link
}

resource "google_compute_managed_ssl_certificate" "this" {
  name = "cdn-ssl-certificate"

  managed {
    domains = [
      "frontend-in-gcp-bucket.developer-friendly.blog",
    ]
  }
}

resource "google_compute_ssl_policy" "this" {
  name            = "cdn-ssl-policy"
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}

resource "google_compute_target_https_proxy" "this" {
  name             = "cdn-https-proxy"
  url_map          = google_compute_url_map.this.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.this.self_link]
  ssl_policy       = google_compute_ssl_policy.this.name
}

resource "google_compute_global_forwarding_rule" "https" {
  for_each = var.public_ip_address

  name       = lower(format("%s-%s", "cdn-https-rule", each.key))
  target     = google_compute_target_https_proxy.this.self_link
  port_range = "443"
  ip_address = each.value
}
