resource "aws_security_group" "this" {
  name   = "bastion"
  vpc_id = var.vpc_id
  tags   = var.tags
}

resource "aws_vpc_security_group_egress_rule" "this" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  tags              = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.this.id
}

resource "aws_eip" "this" {
  instance = aws_instance.this.id
  tags     = var.tags
}
