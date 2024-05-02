data "cloudflare_zone" "this" {
  name = var.root_domain
}

resource "aws_route53_zone" "this" {
  name = format("%s.%s", var.subdomain, var.root_domain)
}

resource "cloudflare_record" "this" {
  for_each = toset(aws_route53_zone.this.name_servers)

  zone_id = data.cloudflare_zone.this.id
  name    = var.subdomain
  type    = "NS"
  value   = each.value
  ttl     = 1

  depends_on = [
    aws_route53_zone.this
  ]
}
