include "gcp" {
  path = find_in_parent_folders("gcp.hcl")
}

inputs = {
  bucket_name       = dependency.gcs.outputs.bucket_name
  public_ip_address = dependency.dns_record.outputs.public_ip_address
}

dependency "gcs" {
  config_path = "../10-storage-bucket"
}

dependency "dns_record" {
  config_path = "../40-dns-record"
}
