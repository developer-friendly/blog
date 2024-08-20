data "http" "this" {
  url = "https://api.ipify.org"
}

resource "hcloud_firewall" "this" {
  name = "k3s-cluster"

  dynamic "rule" {
    for_each = toset({
      ssh            = 22
      kubernetes_api = 6443
    })
    content {
      direction = "in"
      protocol  = "tcp"
      port      = rule.value
      source_ips = [
        format("%s/32", data.http.this.response_body),
      ]
      description = "Admin public IP address"
    }
  }
}

resource "hcloud_firewall_attachment" "this" {
  firewall_id = hcloud_firewall.this.id
  server_ids  = [hcloud_server.this.id]
}
