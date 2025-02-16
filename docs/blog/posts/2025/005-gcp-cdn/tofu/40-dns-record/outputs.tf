output "public_ip_address" {
  value = {
    ipv4 = google_compute_global_address.this["IPV4"].address
    ipv6 = google_compute_global_address.this["IPV6"].address
  }
}
