output "bastion_public_ip" {
  value = aws_eip.this.public_ip
}
