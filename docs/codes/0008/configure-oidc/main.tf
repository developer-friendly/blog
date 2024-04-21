data "terraform_remote_state" "k8s" {
  backend = "local"

  config = {
    path = "../provision-k8s/terraform.tfstate"
  }
}
