resource "hcloud_primary_ip" "this" {
  for_each = toset(["ipv4", "ipv6"])

  name          = "${var.stack_name}-${each.key}"
  datacenter    = var.primary_ip_datacenter
  type          = each.key
  assignee_type = "server"
  auto_delete   = false
}
