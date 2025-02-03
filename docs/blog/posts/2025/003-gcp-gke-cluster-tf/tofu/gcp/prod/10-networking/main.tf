resource "google_compute_network" "this" {
  name                    = module.naming["vpc"].generated_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "this" {
  name          = module.naming["subnet"].generated_name
  network       = google_compute_network.this.id
  ip_cidr_range = "10.0.0.0/14"

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }

  private_ip_google_access = true
}

resource "google_compute_router" "this" {
  name    = module.naming["router"].generated_name
  network = google_compute_network.this.id
}

resource "google_compute_router_nat" "this" {
  name                               = module.naming["nat"].generated_name
  router                             = google_compute_router.this.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_firewall" "this" {
  name    = module.naming["firewall"].generated_name
  network = google_compute_network.this.self_link
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = [
    "0.0.0.0/0",
  ]
}
