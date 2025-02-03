output "network_name" {
  value = google_compute_network.this.name
}

output "subnetwork_name" {
  value = google_compute_subnetwork.this.name
}
