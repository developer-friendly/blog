locals {
  project        = coalesce(var.project, data.google_client_config.current.project)
  generated_name = join("-", compact([local.project, var.environment, var.resource_type, var.suffix]))
}
