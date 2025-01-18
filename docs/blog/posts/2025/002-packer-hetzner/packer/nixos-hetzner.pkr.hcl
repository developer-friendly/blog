packer {
  required_plugins {
    hcloud = {
      version = "< 2.0.0"
      source  = "github.com/hetznercloud/hcloud"
    }
  }
}

variable "hcloud_token" {
  type      = string
  sensitive = true
  default   = env("HCLOUD_TOKEN")
}

locals {
  timestamp      = regex_replace(timestamp(), "[- TZ:]", "")
  ssh_public_key = file(pathexpand("~/.ssh/hetzner-nixos.pub"))

  nixos_version   = "24.11"
  nixpkgs_version = "branch-off-24.11"
}

source "hcloud" "nixos" {
  image         = "debian-12"
  rescue        = "linux64"
  location      = "nbg1"
  server_type   = "cax31" # ARM64, 8 vCPUs, 16 GB RAM, €12/month
  snapshot_name = "nixos-${local.timestamp}"
  snapshot_labels = {
    os          = "nixos"
    nixos       = local.nixos_version
    nixos_major = regex_replace(local.nixos_version, "\\..*", "")
    timestamp   = local.timestamp
  }
  ssh_username = "root"
  token        = "${var.hcloud_token}"
}

build {
  sources = ["source.hcloud.nixos"]

  provisioner "file" {
    content = templatefile("${path.root}/setup-nixos.sh", {
      nixos_version   = local.nixos_version
      nixpkgs_version = local.nixpkgs_version
      ssh_public_key  = local.ssh_public_key
    })
    destination = "/tmp/install.sh"
    direction   = "upload"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/install.sh",
      "/tmp/install.sh",
    ]
  }

  provisioner "shell" {
    inline = [
      "rm -f /tmp/install.sh",
      "sync",
    ]
  }
}
