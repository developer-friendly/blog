server           = true
bootstrap_expect = 1

datacenter = "dc1"
node_name  = "consul-0"

bind_addr   = "0.0.0.0"
client_addr = "0.0.0.0"

data_dir = "/var/lib/consul"

ports {
  http = 8500
  grpc = 8502
}

log_level = "INFO"

ui_config {
  enabled = true
}

acl {
  enabled                  = true
  default_policy           = "deny"
  enable_token_persistence = true
}

retry_join = [
  "127.0.0.1:8301",
]
