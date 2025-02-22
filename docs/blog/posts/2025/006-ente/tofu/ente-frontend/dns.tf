data "cloudflare_zone" "this" {
  zone_id = var.cloudflare_zone_id
}

resource "cloudflare_dns_record" "this" {
  for_each = github_repository.this

  zone_id = data.cloudflare_zone.this.zone_id
  content = "developer-friendly.github.io"
  name    = each.key
  proxied = false
  ttl     = 1
  type    = "CNAME"
}
