module "gke" {
  # The beta-private-cluster module enables beta GKE features and set opinionated defaults.
  # See the module docs https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/tree/master/modules/beta-private-cluster
  #
  # The following configuration creates a cluster that implements many of the recommendations in the GKE hardening guide
  # https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster:
  #  - private GKE cluster with authorized networks
  #  - at least 2 node pools (one default pool, plus one per tenant)
  #  - workload identity
  #  - shielded nodes
  #  - GKE sandbox (gVisor) for the tenant nodes
  #  - Dataplane V2 (which automatically enables network policy)
  #  - secrets encryption
  source  = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  version = "22.0.0"

  authenticator_security_group = var.gke_rbac_security_group_domain != null ? "gke-security-groups@${var.gke_rbac_security_group_domain}" : null

  project_id        = var.project_id
  name              = var.cluster_name
  release_channel   = var.cluster_gke_release_channel
  regional          = var.cluster_regional
  region            = var.region
  zones             = var.zones
  network           = google_compute_network.vpc.name
  subnetwork        = google_compute_subnetwork.subnet.name
  ip_range_pods     = "pods"
  ip_range_services = "services"

  enable_shielded_nodes       = true
  enable_binary_authorization = true
  grant_registry_access       = true

  # Encrypt cluster secrets at the application layer
  database_encryption = [{
    "key_name" : module.kms.keys[var.cluster_secrets_keyname],
    "state" : "ENCRYPTED"
  }]

  # Dataplane V2
  datapath_provider = "ADVANCED_DATAPATH"
  # automatically enabled with Dataplane V2
  network_policy = false

  // Private cluster nodes, public endpoint with authorized networks
  enable_private_nodes         = true
  enable_private_endpoint      = false
  master_global_access_enabled = true
  master_ipv4_cidr_block       = var.master_ipv4_cidr_block
  master_authorized_networks = [
    {
      display_name : "NAT IP",
      cidr_block : format("%s/32", google_compute_address.nat_ip.address)
    },
    # NOTE: we add the local IP of the workstation that applies the Terraform to authorized networks
    {
      display_name : "Local IP",
      cidr_block : "${chomp(data.http.installation_workstation_ip.body)}/32"
    }
  ]
  # open ports for ASM
  add_cluster_firewall_rules = true
  # we don't want ingress into the cluster by default
  http_load_balancing = false

  remove_default_node_pool = true
  node_pools = concat(
    # main node pool
    [{
      name                        = "main-pool"
      image_type                  = "COS_CONTAINERD"
      machine_type                = var.cluster_default_pool_machine_type
      min_count                   = var.cluster_default_pool_min_nodes
      max_count                   = var.cluster_default_pool_max_nodes
      auto_upgrade                = true
      enable_integrity_monitoring = true
      enable_secure_boot          = true
    }],

    # list of tenant nodepools
    [for tenant_name, config in local.tenants : {
      name                        = config.tenant_nodepool_name
      image_type                  = "COS_CONTAINERD"
      machine_type                = var.cluster_tenant_pool_machine_type
      min_count                   = var.cluster_tenant_pool_min_nodes
      max_count                   = var.cluster_tenant_pool_max_nodes
      auto_upgrade                = true
      enable_integrity_monitoring = true
      enable_secure_boot          = true
      # enable GKE sandbox (gVisor) for tenant nodes
      sandbox_enabled = true
      # dedicated service account per tenant node pool
      service_account = format("%s@%s.iam.gserviceaccount.com", config.tenant_nodepool_sa_name, var.project_id)
    }]
  )

  # Add a label with tenant name to each tenant nodepool
  node_pools_labels = {
    for tenant_name, config in local.tenants : config.tenant_nodepool_name => { "tenant" = tenant_name }
  }

  # Add a taint based on the tenant name to each tenant nodepool
  node_pools_taints = {
    for tenant_name, config in local.tenants : config.tenant_nodepool_name => [{
      key    = "tenant"
      value  = tenant_name
      effect = "NO_EXECUTE"
    }]
  }

  depends_on = [
    module.project-services,
    google_service_account.tenant_nodepool_sa
  ]
}

locals {
  # for each tenant, define the names of the nodepool, service accounts etc
  tenants = {
    for name in var.tenant_names : name => {
      tenant_nodepool_name    = format("%s-pool", name)
      tenant_nodepool_sa_name = format("%s-%s-nodes-sa", var.cluster_name, name)
      tenant_apps_sa_name     = format("%s-%s-apps-sa", var.cluster_name, name)
    }
  }
  gke_robot_sa = "service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com"
}

data "google_project" "project" {
  project_id = var.project_id
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}
