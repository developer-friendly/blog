inputs = {
  resource_group_name  = dependency.vnet.outputs.resource_group_name
  virtual_network_name = dependency.vnet.outputs.virtual_network_name
}

dependency "vnet" {
  config_path = "../vnet"
}
