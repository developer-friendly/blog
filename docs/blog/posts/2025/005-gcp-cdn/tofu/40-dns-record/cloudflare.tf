data "cloudflare_zone" "this" {
  zone_id = var.cloudflare_zone_id
}

resource "cloudflare_dns_record" "this" {
  for_each = google_compute_global_address.this

  zone_id = data.cloudflare_zone.this.zone_id
  name    = "frontend-in-gcp-bucket"
  content = each.value.address
  type    = each.key == "IPV4" ? "A" : "AAAA"
  proxied = false
  ttl     = 60
}
