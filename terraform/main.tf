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
  version = "26.1.1"

  add_cluster_firewall_rules   = true
  authenticator_security_group = var.gke_rbac_security_group_domain != null ? "gke-security-groups@${var.gke_rbac_security_group_domain}" : null
  datapath_provider            = "ADVANCED_DATAPATH"
  enable_binary_authorization  = true
  enable_private_endpoint      = false
  enable_private_nodes         = true
  enable_shielded_nodes        = true
  grant_registry_access        = true
  http_load_balancing          = false
  ip_range_pods                = "pods"
  ip_range_services            = "services"
  master_global_access_enabled = true
  master_ipv4_cidr_block       = var.master_ipv4_cidr_block
  name                         = var.cluster_name
  network                      = module.fedlearn-vpc.network_name
  network_policy               = false # automatically enabled with Dataplane V2
  project_id                   = data.google_project.project.project_id
  region                       = var.region
  regional                     = var.cluster_regional
  release_channel              = var.cluster_gke_release_channel
  remove_default_node_pool     = true
  subnetwork                   = module.fedlearn-vpc.subnets[local.fedlearn_subnet_key].name
  zones                        = var.zones


  # Encrypt cluster secrets at the application layer
  database_encryption = [{
    "key_name" : module.kms.keys[var.cluster_secrets_keyname],
    "state" : "ENCRYPTED"
  }]

  master_authorized_networks = [
    {
      display_name : "NAT IP",
      cidr_block : format("%s/32", google_compute_address.nat_ip.address)
    },
    # Add the local IP of the workstation that applies the Terraform to authorized networks
    {
      display_name : "Local IP",
      cidr_block : "${chomp(data.http.installation_workstation_ip.body)}/32"
    }
  ]

  node_pools = [for tenant_name, config in local.tenants : {
    auto_upgrade                = true
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    image_type                  = "COS_CONTAINERD"
    machine_type                = tenant_name == local.main_node_pool_name ? var.cluster_default_pool_machine_type : var.cluster_tenant_pool_machine_type
    max_count                   = tenant_name == local.main_node_pool_name ? var.cluster_default_pool_max_nodes : var.cluster_tenant_pool_max_nodes
    min_count                   = tenant_name == local.main_node_pool_name ? var.cluster_default_pool_min_nodes : var.cluster_tenant_pool_min_nodes
    name                        = config.tenant_nodepool_name
    sandbox_enabled             = tenant_name == local.main_node_pool_name ? false : true
    service_account             = format("%s@%s.iam.gserviceaccount.com", config.tenant_nodepool_sa_name, data.google_project.project.project_id)
  }]

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
    module.fedlearn-vpc,
    module.project-iam-bindings,
    module.project-services,
    module.service_accounts,
  ]
}

locals {

  main_node_pool_name = "${local.tenant_and_main_pool_names[0]}-pool"

  # To reduce duplication, treat the main pool as the first (privileged) tenant
  tenant_and_main_pool_names = concat(
    ["main"],
    var.tenant_names
  )

  tenants = {
    for name in local.tenant_and_main_pool_names : name => {
      tenant_nodepool_name    = format("%s-pool", name)
      tenant_nodepool_sa_name = format("%s-%s-nodes-sa", var.cluster_name, name)
      tenant_apps_sa_name     = format("%s-%s-apps-sa", var.cluster_name, name)
    }
  }
  gke_robot_sa = "service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com"

  # We can't use module.service_accounts.emails because of
  # https://github.com/terraform-google-modules/terraform-google-service-accounts/issues/59
  list_nodepool_sa_emails = [for tenant in local.tenants : module.service_accounts.service_accounts_map[tenant.tenant_nodepool_sa_name].email]

  # We can't use module.service_accounts.iam_emails because of
  # https://github.com/terraform-google-modules/terraform-google-service-accounts/issues/59
  list_nodepool_sa_iam_emails = [for tenant in local.tenants : "serviceAccount:${module.service_accounts.service_accounts_map[tenant.tenant_nodepool_sa_name].email}"]

  list_sa_names = concat(
    [for tenant in local.tenants : tenant.tenant_nodepool_sa_name],
    [for tenant in local.tenants : tenant.tenant_apps_sa_name],
  )
}

data "google_project" "project" {
  project_id = var.project_id

  depends_on = [
    module.project-services
  ]
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}
