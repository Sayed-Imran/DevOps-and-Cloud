output "cluster_name" {
  description = "The name of the Kubernetes cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "The endpoint of the Kubernetes cluster"
  value       = google_container_cluster.primary.endpoint
}

output "cluster_master_version" {
  description = "The master version of the Kubernetes cluster"
  value       = google_container_cluster.primary.master_version
}