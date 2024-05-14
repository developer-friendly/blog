output "external_secret_name" {
  value = kubernetes_manifest.external_secret.manifest.metadata.name
}

output "external_secret_namespace" {
  value = kubernetes_manifest.external_secret.manifest.metadata.namespace
}

output "cluster_issuer_name" {
  value = kubernetes_manifest.cluster_issuer.manifest.metadata.name
}
