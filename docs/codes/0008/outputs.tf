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

output "ansible_inventory_yaml" {
  value = <<-EOF
    k8s:
      hosts:
        ${var.stack_name}:
          ansible_host: ${hcloud_server.this.ipv4_address}
          ansible_user: ${var.username}
          ansible_ssh_private_key_file: ~/.ssh/k3s-cluster
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no'
  EOF
}
