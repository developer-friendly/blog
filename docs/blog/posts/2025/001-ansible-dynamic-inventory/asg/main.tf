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

locals {
  tls_public_key = file(pathexpand("~/.ssh/ansible-dynamic.pub"))
}

resource "aws_key_pair" "this" {
  key_name   = "tofu"
  public_key = local.tls_public_key
  tags       = var.tags
}

resource "aws_launch_template" "this" {
  name_prefix   = "ansible"
  image_id      = data.aws_ami.this.id
  instance_type = "t4g.nano"
  key_name      = aws_key_pair.this.key_name

  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = "0.01"
    }
  }

  vpc_security_group_ids = [
    aws_security_group.this.id,
  ]


  user_data = base64encode(file("${path.module}/cloud-init.yml"))

  tags = var.tags
}

resource "aws_autoscaling_group" "this" {
  name_prefix = "ansible"

  capacity_rebalance  = true
  desired_capacity    = 3
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = module.vpc.private_subnets
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }

  }

  timeouts {
    delete = "5m"
  }
}
