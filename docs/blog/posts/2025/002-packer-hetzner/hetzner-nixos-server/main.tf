terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "< 2"
    }
  }
}

data "hcloud_image" "nixos_image" {
  with_selector = "nixos_major=24"
  most_recent = true
}

resource "hcloud_server" "this" {
  name        = "nixos-server"
  image       = data.hcloud_image.nixos_image.id
  server_type = "cax31"
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
}
