resource "google_compute_network" "vpc" {
  name                    = "fedlearn-network"
  project                 = var.project_id
  auto_create_subnetworks = false

  depends_on = [
    module.project-services
  ]
}

resource "google_compute_subnetwork" "subnet" {
  name                     = "subnet-01"
  ip_cidr_range            = "10.2.0.0/16"
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.20.0.0/14"
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.24.0.0/20"
  }
}

resource "google_compute_router" "router" {
  name    = "router"
  region  = google_compute_subnetwork.subnet.region
  network = google_compute_network.vpc.id
}

resource "google_compute_address" "nat_ip" {
  name   = "nat-manual-ip"
  region = google_compute_subnetwork.subnet.region
}

resource "google_compute_router_nat" "nat" {
  name   = "fl-nat-gateway"
  router = google_compute_router.router.name
  region = google_compute_router.router.region

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = [google_compute_address.nat_ip.self_link]

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

# IP address of the machine that this Terraform operation is running on.
# This IP is added to "authorized networks" for access to GKE control plane
data "http" "installation_workstation_ip" {
  url = "http://ipv4.icanhazip.com"
}
