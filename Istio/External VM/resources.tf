resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone
  network    = var.network
  subnetwork = var.subnetwork


  private_cluster_config {
    enable_private_nodes    = true
  }
  ip_allocation_policy {
    cluster_ipv4_cidr_block = var.pod_cidr
    services_ipv4_cidr_block = var.service_cidr
  }

  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }
    http_load_balancing {
      disabled = false
    }

  }

  release_channel {
    channel = "REGULAR"
  }

  node_pool {
    name       = "default-pool"
    initial_node_count = var.node_count
    max_pods_per_node = var.max_pods_per_node
    node_config {
      machine_type = var.node_machine_type
      disk_size_gb = var.disk_size_gb
      image_type   = "COS_CONTAINERD"
      oauth_scopes = [
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring",
        "https://www.googleapis.com/auth/servicecontrol",
        "https://www.googleapis.com/auth/service.management.readonly",
        "https://www.googleapis.com/auth/trace.append"
      ]
      metadata = {
        disable-legacy-endpoints = "true"
      }
      tags = ["kubernetes-nodes"]
    }
    management {
      auto_upgrade = true
      auto_repair  = true
    }
    upgrade_settings {
      max_surge       = 1
      max_unavailable = 0
    }
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  enable_shielded_nodes = true
  master_authorized_networks_config {
    gcp_public_cidrs_access_enabled = true
  }
}

resource "google_compute_instance" "external_vm" {
  name         = "external-vm"
  machine_type = "e3-standard-2"
  zone = var.zone
  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
    }
  }
  tags = ["external-vm"]
  network_interface {
    network    = "default"
    subnetwork = "default"

    access_config {
    }
  }
}

resource "google_compute_firewall" "allow_kubernetes_pod_cidr" {
  name    = "allow-kubernetes-pod"
  network = var.network

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  source_ranges = [var.pod_cidr]
  target_tags = [var.network_tags_for_vm]
  provisioner "remote-exec" {
      
  }
}

