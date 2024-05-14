data "cloudflare_zone" "this" {
  name = var.root_domain
}

resource "random_uuid" "this" {}

resource "cloudflare_record" "this" {
  zone_id = data.cloudflare_zone.this.id

  name    = "${random_uuid.this.id}.${var.root_domain}"
  proxied = false
  ttl     = 60
  type    = "A"
  value   = hcloud_primary_ip.this["ipv4"].ip_address
}


resource "cloudflare_record" "this_v6" {
  zone_id = data.cloudflare_zone.this.id

  name    = "${random_uuid.this.id}.${var.root_domain}"
  proxied = false
  ttl     = 60
  type    = "AAAA"
  value   = hcloud_primary_ip.this["ipv6"].ip_address
}
