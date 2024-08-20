output "cluster_issuer_name" {
  value = kubernetes_manifest.cluster_issuer.manifest.metadata.name
}
