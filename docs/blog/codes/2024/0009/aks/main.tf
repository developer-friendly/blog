data "http" "this" {
  url = "https://checkip.amazonaws.com"
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

module "aks" {
  source  = "Azure/aks/azurerm"
  version = "8.0.0"

  prefix = var.prefix

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  kubernetes_version = var.kubernetes_version

  admin_username = var.admin_username

  agents_count = var.agents_count
  agents_size  = var.agents_size

  network_plugin      = "azure"
  network_plugin_mode = "overlay"
  ebpf_data_plane     = "cilium"

  oidc_issuer_enabled = true

  only_critical_addons_enabled = true

  public_ssh_key = tls_private_key.this.public_key_openssh

  rbac_aad                          = true
  rbac_aad_managed                  = true
  rbac_aad_azure_rbac_enabled       = false
  role_based_access_control_enabled = true

  log_analytics_workspace_enabled = false

  identity_type = "SystemAssigned"

  api_server_authorized_ip_ranges = [
    "${trimspace(data.http.this.response_body)}/32",
  ]

  depends_on = [
    azurerm_resource_group.this
  ]
}

resource "null_resource" "this" {
  triggers = {
    aks_id = module.aks.aks_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      az aks get-credentials \
      --resource-group ${var.resource_group_name} \
      --name ${module.aks.aks_name} \
      --admin
    EOT
  }

  depends_on = [
    module.aks
  ]
}
