data "aws_ami" "this" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

data "http" "current" {
  url = "http://checkip.amazonaws.com"
}

data "aws_vpc" "this" {
  id = var.vpc_id
}
