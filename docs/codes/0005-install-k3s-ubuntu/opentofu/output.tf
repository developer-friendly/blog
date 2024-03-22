output "server_ipv4_address" {
  value = hcloud_server.this.ipv4_address
}

output "server_ipv6_address" {
  value = hcloud_server.this.ipv6_address
}
