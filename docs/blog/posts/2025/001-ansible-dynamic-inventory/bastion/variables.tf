variable "tags" {
  type = map(string)
  default = {
    Name        = "bastion"
    provisioner = "tofu"
    inventory   = "bastion"
    cloud       = "aws"
  }
}

variable "vpc_id" {
  type     = string
  nullable = false
}

variable "key_pair_name" {
  type     = string
  nullable = false
}

variable "public_subnets" {
  type     = list(string)
  nullable = false
}
