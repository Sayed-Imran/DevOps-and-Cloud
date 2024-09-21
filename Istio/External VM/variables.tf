variable "project_id" {
  description = "The ID of the project in which to create the cluster"
  type        = string
}

variable "region" {
  description = "The region in which to create the cluster"
  type        = string
  default     = "asia-south1"
}

variable "zone" {
  description = "The zone in which to create the cluster"
  type        = string
  default     = "asia-south1-a"
}

variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
  default     = "my-cluster"
}

variable "network" {
  description = "The VPC network to host the cluster in"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "The subnetwork to host the cluster in"
  type        = string
  default     = "default"
}

variable "node_count" {
  description = "The number of nodes in the cluster"
  type        = number
  default     = 3
}

variable "node_machine_type" {
  description = "The machine type to use for nodes"
  type        = string
  default     = "e2-standard-4"
}

variable "disk_size_gb" {
  description = "The size of the disk attached to each node"
  type        = number
  default     = 15
}

variable "max_pods_per_node" {
  description = "The maximum number of pods per node"
  type        = number
  default     = 20
}

variable "default_max_pods_per_node" {
  description = "The default maximum number of pods per node"
  type        = number
  default     = 110
}
variable "pod_cidr" {
  description = "The CIDR block for the pods in the cluster"
  type        = string
}

variable "service_cidr" {
  description = "The CIDR block for the services in the cluster"
  type        = string
}

variable "network_tags_for_vm" {
  description = "Network tags for external VM"
  type =  string
  default = "external-vm"
}
variable "vm_user" {
  description = "The user to connect to the external VM"
  type        = string
  default     = "ubuntu"
}