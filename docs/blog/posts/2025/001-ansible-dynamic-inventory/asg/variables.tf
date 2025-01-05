variable "tags" {
  type = map(string)
  default = {
    Name        = "worker"
    provisioner = "tofu"
    inventory   = "worker"
    cloud       = "aws"
  }
}
