# Step 1: Define the provider
provider "google" {
  project = var.project_id
  region  = var.region
}
