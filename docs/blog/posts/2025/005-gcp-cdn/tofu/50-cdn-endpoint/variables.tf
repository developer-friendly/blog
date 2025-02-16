variable "bucket_name" {
  type     = string
  nullable = false
}

variable "public_ip_address" {
  type = map(string)
  nullable = false
}
