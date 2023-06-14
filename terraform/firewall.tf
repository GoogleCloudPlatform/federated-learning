locals {
  # list of dedicated service accounts used by the tenant node pools and the main node pool
  list_nodepool_sa = concat(
    [for sa in google_service_account.tenant_nodepool_sa : sa.email],
    [google_service_account.main_nodepool_sa.email]
  )
}

# deny all egress from the FL node pool
resource "google_compute_firewall" "node-pools-deny-egress" {
  name                    = "node-pools-deny-egress"
  description             = "Default deny egress from node pools"
  project                 = data.google_project.project.project_id
  network                 = module.fedlearn-vpc.network_id
  direction               = "EGRESS"
  target_service_accounts = local.list_nodepool_sa
  deny {
    protocol = "all"
  }
  priority = 65535
}

resource "google_compute_firewall" "node-pools-allow-egress-nodes-pods-services" {
  name                    = "node-pools-allow-egress-nodes-pods-services"
  description             = "Allow egress from node pools to cluster nodes, pods and services"
  project                 = data.google_project.project.project_id
  network                 = module.fedlearn-vpc.network_id
  direction               = "EGRESS"
  target_service_accounts = local.list_nodepool_sa
  destination_ranges      = [module.fedlearn-vpc.subnets[local.fedlearn_subnet_key].ip_cidr_range, local.fedlearn_pods_ip_range, local.fedlearn_services_ip_range]
  allow {
    protocol = "all"
  }
  priority = 1000
}

resource "google_compute_firewall" "node-pools-allow-egress-api-server" {
  name                    = "node-pools-allow-egress-api-server"
  description             = "Allow egress from node pools to the Kubernetes API server"
  project                 = data.google_project.project.project_id
  network                 = module.fedlearn-vpc.network_id
  direction               = "EGRESS"
  target_service_accounts = local.list_nodepool_sa
  destination_ranges      = [var.master_ipv4_cidr_block]
  allow {
    protocol = "tcp"
    ports    = [443, 10250]
  }
  priority = 1000
}

resource "google_compute_firewall" "node-pools-allow-egress-google-apis" {
  name                    = "node-pools-allow-egress-google-apis"
  description             = "Allow egress from node pools to Google APIs via Private Google Access"
  project                 = data.google_project.project.project_id
  network                 = module.fedlearn-vpc.network_id
  direction               = "EGRESS"
  target_service_accounts = local.list_nodepool_sa
  destination_ranges      = ["199.36.153.8/30"]
  allow {
    protocol = "tcp"
  }
  priority = 1000
}

# Dev / Testing
# Allow ssh tunnel-through-iap to all cluster nodes
# See https://cloud.google.com/iap/docs/using-tcp-forwarding#create-firewall-rule
resource "google_compute_firewall" "allow-ssh-tunnel-iap" {
  name      = "allow-ssh-tunnel-iap"
  project   = data.google_project.project.project_id
  network   = module.fedlearn-vpc.network_id
  direction = "INGRESS"
  # This range contains all IP addresses that IAP uses for TCP forwarding.
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["gke-${var.cluster_name}"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  priority = 1000
}
