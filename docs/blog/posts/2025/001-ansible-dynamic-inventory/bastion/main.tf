data "aws_ami" "this" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}

resource "aws_instance" "this" {
  ami = data.aws_ami.this.id

  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = "0.01"
    }
  }

  instance_type = "t4g.nano"

  key_name = var.key_pair_name

  subnet_id = var.public_subnets[0]


  user_data = file("${path.module}/cloud-init.yml")

  vpc_security_group_ids = [
    aws_security_group.this.id,
  ]

  tags = var.tags
}
