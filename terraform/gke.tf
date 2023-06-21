# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
  create_service_account       = false
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
    machine_type                = tenant_name == local.main_tenant_name ? var.cluster_default_pool_machine_type : var.cluster_tenant_pool_machine_type
    max_count                   = tenant_name == local.main_tenant_name ? var.cluster_default_pool_max_nodes : var.cluster_tenant_pool_max_nodes
    min_count                   = tenant_name == local.main_tenant_name ? var.cluster_default_pool_min_nodes : var.cluster_tenant_pool_min_nodes
    name                        = config.tenant_nodepool_name
    sandbox_enabled             = tenant_name == local.main_tenant_name ? false : true
    service_account             = format("%s@%s.iam.gserviceaccount.com", config.tenant_nodepool_sa_name, data.google_project.project.project_id)
  }]

  # Add a label with tenant name to each tenant nodepool
  node_pools_labels = {
    for tenant_name, config in local.tenants : config.tenant_nodepool_name => {
      "tenant" = tenant_name
    } if tenant_name != local.main_tenant_name
  }

  # Add a taint based on the tenant name to each tenant nodepool
  node_pools_taints = {
    for tenant_name, config in local.tenants : config.tenant_nodepool_name => [{
      key    = "tenant"
      value  = tenant_name
      effect = "NO_EXECUTE"
    }] if tenant_name != local.main_tenant_name
  }

  depends_on = [
    module.fedlearn-vpc,
    module.project-iam-bindings,
    module.project-services,
    module.service_accounts,
  ]
}