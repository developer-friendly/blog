data "cloudflare_zone" "devfriend_blog" {
  name = "developer-friendly.blog"
}

resource "cloudflare_record" "ory" {
  zone_id = data.cloudflare_zone.devfriend_blog.id

  name    = "ory"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "developer-friendly.github.io"
}
