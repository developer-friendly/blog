resource "google_compute_global_address" "this" {
  for_each = toset([
    "IPV4",
    "IPV6",
  ])

  name         = lower(format("%s-%s", "cdn-ip-address", each.key))
  address_type = "EXTERNAL"
  ip_version   = each.key
}
