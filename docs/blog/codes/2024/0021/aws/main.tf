locals {
  controlplane_ip = "${trimspace(data.http.current.response_body)}/32"
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
}

resource "aws_key_pair" "this" {
  key_name   = "bastion"
  public_key = tls_private_key.this.public_key_openssh
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.this.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.this.key_name
  vpc_security_group_ids = [aws_security_group.this.id]

  associate_public_ip_address = true

  tags = {
    Name = "bastion"
  }
}
