inputs = {
  bastion_nsg_id = dependency.worker.outputs.bastion_nsg_id
  key_pair_name  = dependency.worker.outputs.aws_key_pair_name
  public_subnets = dependency.worker.outputs.public_subnets
  vpc_id         = dependency.worker.outputs.vpc_id
}

dependency "worker" {
  config_path = "../aws-worker"
}
