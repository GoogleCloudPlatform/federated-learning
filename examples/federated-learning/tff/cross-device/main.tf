data "google_client_config" "default" {}

data "google_project" "project" {
  project_id = var.project_id
}

data "google_container_cluster" "gke" {
  name     = "autopilot-cluster-1"
  location = "europe-west1"
}
