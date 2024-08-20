output "public_ip" {
  value = hcloud_primary_ip.this["ipv4"].ip_address
}

output "public_ipv6" {
  value = hcloud_primary_ip.this["ipv6"].ip_address
}
