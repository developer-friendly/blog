output "public_ip" {
  value = hcloud_primary_ip.this["ipv4"].ip_address
}

output "public_ipv6" {
  value = hcloud_primary_ip.this["ipv6"].ip_address
}

output "ssh_private_key" {
  value     = tls_private_key.this.private_key_pem
  sensitive = true
}
