resource "tls_private_key" "this" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "hcloud_ssh_key" "this" {
  name       = var.stack_name
  public_key = tls_private_key.this.public_key_openssh
}

resource "hcloud_server" "this" {
  name        = var.stack_name
  server_type = "cax11"
  image       = "ubuntu-22.04"
  location    = "nbg1"

  ssh_keys = [
    hcloud_ssh_key.this.id,
  ]

  public_net {
    ipv4 = hcloud_primary_ip.this["ipv4"].id
    ipv6 = hcloud_primary_ip.this["ipv6"].id
  }

  user_data = <<-EOF
    #cloud-config
    users:
      - name: ${var.username}
        groups: users, admin, adm
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        ssh_authorized_keys:
          - ${tls_private_key.this.public_key_openssh}
    packages:
      - certbot
    package_update: true
    package_upgrade: true
    runcmd:
      - sed -i -e '/^\(#\|\)PermitRootLogin/s/^.*$/PermitRootLogin no/' /etc/ssh/sshd_config
      - sed -i -e '/^\(#\|\)PasswordAuthentication/s/^.*$/PasswordAuthentication no/' /etc/ssh/sshd_config
      - sed -i '$a AllowUsers ${var.username}' /etc/ssh/sshd_config
      - |
        curl https://get.k3s.io | \
          INSTALL_K3S_VERSION="v1.29.3+k3s1" \
          INSTALL_K3S_EXEC="--disable traefik
            --disable-network-policy
            --flannel-backend none
            --write-kubeconfig /home/${var.username}/.kube/config
            --secrets-encryption" \
          sh -
      - chown -R ${var.username}:${var.username} /home/${var.username}/.kube/
      - |
        CILIUM_CLI_VERSION=v0.16.4
        CLI_ARCH=arm64
        curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/$CILIUM_CLI_VERSION/cilium-linux-$CLI_ARCH.tar.gz{,.sha256sum}
        sha256sum --check cilium-linux-$CLI_ARCH.tar.gz.sha256sum
        sudo tar xzvfC cilium-linux-$CLI_ARCH.tar.gz /usr/local/bin
      - kubectl completion bash | tee /etc/bash_completion.d/kubectl
      - k3s completion bash | tee /etc/bash_completion.d/k3s
      - |
        cat << 'EOF2' >> /home/${var.username}/.bashrc
        alias k=kubectl
        complete -F __start_kubectl k
        EOF2
      - reboot
  EOF
}
