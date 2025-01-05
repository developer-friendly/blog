output "aws_key_pair_name" {
  value = aws_key_pair.this.key_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}
