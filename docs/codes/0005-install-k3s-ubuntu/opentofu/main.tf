resource "hcloud_server" "this" {
  name        = "k3s-cluster"
  server_type = "cax11" # ARM64, 2vCPU, 4GB RAM
  image       = "ubuntu-22.04"
  location    = "nbg1" # Nuernberg DC

  user_data = file("${path.module}/cloud-init.yml")
}
