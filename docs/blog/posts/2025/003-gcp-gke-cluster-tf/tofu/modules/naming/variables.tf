variable "project" {
  type        = string
  description = "The project name or ID"
  default     = ""
}

variable "environment" {
  type        = string
  description = "The environment (e.g., dev, prod)"
}

variable "resource_type" {
  type        = string
  description = "The type of resource (e.g., bucket, vm)"
}

variable "suffix" {
  type        = string
  description = "An optional suffix for the resource name"
  default     = ""
}
