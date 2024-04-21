data "http" "this" {
  url = "https://checkip.amazonaws.com"
}

resource "hcloud_firewall" "this" {
  name = var.stack_name

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = 22
    source_ips  = [format("%s/32", trimspace(data.http.this.response_body))]
    description = "Allow SSH access from my IP"
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = 80
    source_ips = [
      "0.0.0.0/0",
      "::/0",
    ]
    description = "Allow HTTP access from everywhere"
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = 443
    source_ips = [
      "0.0.0.0/0",
      "::/0",
    ]
    description = "Allow HTTPS access from everywhere"
  }


  depends_on = [
    hcloud_server.this,
  ]
}

resource "hcloud_firewall_attachment" "this" {
  firewall_id = hcloud_firewall.this.id
  server_ids  = [hcloud_server.this.id]
}
