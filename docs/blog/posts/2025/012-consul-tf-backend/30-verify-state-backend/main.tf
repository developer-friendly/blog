terraform {
  backend "consul" {
    address = "https://tofu.developer-friendly.blog"
    path    = "tf/verify-state-backend"
    scheme  = "https"
    # token   = "<CONSUL_HTTP_TOKEN>"
  }
}

resource "null_resource" "this" {
  provisioner "local-exec" {
    command = "echo 'Terraform state backend configured with Consul'"
  }
}
