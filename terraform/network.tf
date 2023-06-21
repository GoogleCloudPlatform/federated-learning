locals {
  fedlearn_subnet_name = "subnet-01"
  fedlearn_subnet_key  = "${var.region}/${local.fedlearn_subnet_name}"

  fedlearn_pods_ip_range     = "10.20.0.0/14"
  fedlearn_services_ip_range = "10.24.0.0/20"
}

module "fedlearn-vpc" {
  source  = "terraform-google-modules/network/google"
  version = "7.0.0"

  project_id   = data.google_project.project.project_id
  network_name = "fedlearn-network"
  routing_mode = "GLOBAL"

  firewall_rules = [
    {
      description             = "Default deny egress from node pools"
      direction               = "EGRESS"
      name                    = "node-pools-deny-egress"
      priority                = 65535
      target_service_accounts = local.list_nodepool_sa_emails

      deny = [
        {
          protocol = "all"
        }
      ]
    },
    {
      description             = "Allow egress from node pools to cluster nodes, pods and services"
      direction               = "EGRESS"
      name                    = "node-pools-allow-egress-nodes-pods-services"
      priority                = 1000
      ranges                  = [module.fedlearn-vpc.subnets[local.fedlearn_subnet_key].ip_cidr_range, local.fedlearn_pods_ip_range, local.fedlearn_services_ip_range]
      target_service_accounts = local.list_nodepool_sa_emails

      allow = [
        {
          protocol = "all"
        }
      ]
    },
    {
      description             = "Allow egress from node pools to the Kubernetes API server"
      destination_ranges      = [var.master_ipv4_cidr_block]
      direction               = "EGRESS"
      name                    = "node-pools-allow-egress-api-server"
      priority                = 1000
      target_service_accounts = local.list_nodepool_sa_emails

      allow = [
        {
          protocol = "tcp"
          ports    = [443, 10250]
        }
      ]
    },
    {
      description             = "Allow egress from node pools to Google APIs via Private Google Access"
      destination_ranges      = ["199.36.153.8/30"]
      direction               = "EGRESS"
      name                    = "node-pools-allow-egress-google-apis"
      priority                = 1000
      target_service_accounts = local.list_nodepool_sa_emails

      allow = [
        {
          protocol = "tcp"
        }
      ]
    },
    {
      name        = "allow-ssh-tunnel-iap"
      description = "Allow ssh tunnel-through-iap to all cluster nodes. Useful during development and testing."
      direction   = "INGRESS"
      priority    = 1000
      target_tags = ["gke-${var.cluster_name}"]

      # This range contains all IP addresses that IAP uses for TCP forwarding.
      # See https://cloud.google.com/iap/docs/using-tcp-forwarding#create-firewall-rule
      ranges = ["35.235.240.0/20"]

      allow = [
        {
          protocol = "tcp"
          ports    = ["22"]
        }
      ]
    }
  ]

  subnets = [
    {
      subnet_name           = local.fedlearn_subnet_name
      subnet_ip             = "10.2.0.0/16"
      subnet_private_access = "true"
      subnet_region         = var.region
    }
  ]

  secondary_ranges = {
    subnet-01 = [
      {
        range_name    = "pods"
        ip_cidr_range = local.fedlearn_pods_ip_range
      },
      {
        range_name    = "services"
        ip_cidr_range = local.fedlearn_services_ip_range
      },
    ]
  }

  depends_on = [
    module.project-services
  ]
}

resource "google_compute_address" "nat_ip" {
  name   = "nat-manual-ip"
  region = module.fedlearn-vpc.subnets[local.fedlearn_subnet_key].region
}

module "cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "5.0.1"

  name    = "fl-router"
  network = module.fedlearn-vpc.network_id
  project = data.google_project.project.project_id
  region  = module.fedlearn-vpc.subnets[local.fedlearn_subnet_key].region

  nats = [
    {
      name                               = "fl-nat-gateway"
      nat_ip_allocate_option             = "MANUAL_ONLY"
      source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

      nat_ips = [google_compute_address.nat_ip.self_link]

      subnetworks = [
        {
          name                    = module.fedlearn-vpc.subnets[local.fedlearn_subnet_key].self_link
          source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
        }
      ]
    }
  ]
}

# IP address of the machine that this Terraform operation is running on.
# This IP is added to "authorized networks" for access to GKE control plane
data "http" "installation_workstation_ip" {
  url = "http://ipv4.icanhazip.com"
}
