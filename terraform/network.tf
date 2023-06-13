locals {
  fedlearn_subnet_key = "${var.region}/subnet-01"
}


module "fedlearn-vpc" {
  source  = "terraform-google-modules/network/google"
  version = "7.0.0"

  delete_default_internet_gateway_routes = true
  project_id                             = var.project_id
  network_name                           = "fedlearn-network"
  routing_mode                           = "GLOBAL"

  subnets = [
    {
      subnet_name   = local.fedlearn_subnet_name
      subnet_ip     = "10.2.0.0/16"
      subnet_region = var.region
    }
  ]

  secondary_ranges = {
    subnet-01 = [
      {
        range_name    = "pods"
        ip_cidr_range = "10.20.0.0/14"
      },
      {
        range_name    = "services"
        ip_cidr_range = "10.24.0.0/20"
      },
    ]
  }

  depends_on = [
    module.project-services
  ]
}

resource "google_compute_router" "router" {
  name    = "router"
  region  = module.fedlearn-vpc.subnets[local.fedlearn_subnet_name].subnet_region
  network = module.fedlearn-vpc.network_id
}

resource "google_compute_address" "nat_ip" {
  name   = "nat-manual-ip"
  region = module.fedlearn-vpc.subnets[local.fedlearn_subnet_name].subnet_region
}

resource "google_compute_router_nat" "nat" {
  name   = "fl-nat-gateway"
  router = google_compute_router.router.name
  region = google_compute_router.router.region

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = [google_compute_address.nat_ip.self_link]

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = module.fedlearn-vpc.subnets[local.fedlearn_subnet_name].self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

# IP address of the machine that this Terraform operation is running on.
# This IP is added to "authorized networks" for access to GKE control plane
data "http" "installation_workstation_ip" {
  url = "http://ipv4.icanhazip.com"
}
