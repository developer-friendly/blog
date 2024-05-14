variable "root_domain" {
  type    = string
  default = "developer-friendly.blog"
}

variable "subdomain" {
  type    = string
  default = "aws"
}

variable "cloudflare_api_token" {
  type      = string
  nullable  = false
  sensitive = true
}
