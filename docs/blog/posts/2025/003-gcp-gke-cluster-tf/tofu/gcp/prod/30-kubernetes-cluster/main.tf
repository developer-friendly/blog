data "google_project" "current" {}
data "http" "my_ip" {
  url = "http://checkip.amazonaws.com/"
}

data "google_iam_policy" "encryptor" {
  binding {
    role = "roles/cloudkms.cryptoKeyEncrypter"

    members = [
      "serviceAccount:service-${data.google_project.current.number}@container-engine-robot.iam.gserviceaccount.com"
    ]
  }

  binding {
    role = "roles/cloudkms.cryptoKeyDecrypter"

    members = [
      "serviceAccount:service-${data.google_project.current.number}@container-engine-robot.iam.gserviceaccount.com"
    ]
  }
}

resource "google_kms_crypto_key_iam_policy" "this" {
  crypto_key_id = var.kms_key_id
  policy_data   = data.google_iam_policy.encryptor.policy_data
}

resource "google_container_cluster" "this" {
  name = module.naming["gke"].generated_name

  enable_autopilot = true

  release_channel {
    channel = "STABLE"
  }

  initial_node_count = 1

  deletion_protection = true

  networking_mode = "VPC_NATIVE"

  datapath_provider = "ADVANCED_DATAPATH"

  network    = var.network_name
  subnetwork = var.subnetwork_name

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.4.0.0/14"
    services_ipv4_cidr_block = "10.8.0.0/16"
  }

  cluster_autoscaling {


    auto_provisioning_defaults {
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
      ]
    }
  }

  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "APISERVER",
      "CONTROLLER_MANAGER",
      "SCHEDULER",
      "WORKLOADS",
    ]
  }

  monitoring_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "APISERVER",
      "SCHEDULER",
      "CONTROLLER_MANAGER",
      "STORAGE",
      "HPA",
      "POD",
      "DAEMONSET",
      "DEPLOYMENT",
      "STATEFULSET",
      "KUBELET",
      "CADVISOR",
    ]

    advanced_datapath_observability_config {
      enable_metrics = true
      enable_relay   = true
    }

  }

  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  node_config {
    workload_metadata_config {
      mode = "GCE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  master_authorized_networks_config {
    gcp_public_cidrs_access_enabled = true
    cidr_blocks {
      cidr_block   = format("%s/32", trimspace(data.http.my_ip.response_body))
      display_name = "admin"
    }
  }

  maintenance_policy {
    recurring_window {
      start_time = "2025-01-01T00:00:00Z"
      end_time   = "2025-01-01T06:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
    }
  }

  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }

  enable_cilium_clusterwide_network_policy = true

  enable_l4_ilb_subsetting = true

  secret_manager_config {
    enabled = true
  }

  security_posture_config {
    mode               = "BASIC"
    vulnerability_mode = "VULNERABILITY_BASIC"
  }

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
  }

  workload_identity_config {
    workload_pool = "${data.google_project.current.project_id}.svc.id.goog"
  }

  identity_service_config {
    enabled = true
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }

    gcp_filestore_csi_driver_config {
      enabled = true
    }

    gcs_fuse_csi_driver_config {
      enabled = true
    }

    gce_persistent_disk_csi_driver_config {
      enabled = true
    }

    gke_backup_agent_config {
      enabled = true
    }

    parallelstore_csi_driver_config {
      enabled = true
    }
  }

  database_encryption {
    state    = "ENCRYPTED"
    key_name = var.kms_key_id
  }

  resource_labels = {
    env = "prod"
  }
}
