module "service_accounts" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.2.1"
  project_id = data.google_project.project.project_id

  grant_billing_role = false
  grant_xpn_roles    = false
  names              = local.list_sa_names

  depends_on = [
    module.project-services
  ]
}

# default roles for the node SAs
module "project-iam-bindings" {
  source   = "terraform-google-modules/iam/google//modules/projects_iam"
  version  = "7.6.0"
  projects = [data.google_project.project.project_id]
  mode     = "authoritative"

  bindings = {
    # Least-privilege roles needed for a node pool service account to function and
    # to get read-only access to Container Registry and Artifact Registry
    "roles/logging.logWriter"                   = local.list_nodepool_sa_iam_emails,
    "roles/monitoring.metricWriter"             = local.list_nodepool_sa_iam_emails,
    "roles/monitoring.viewer"                   = local.list_nodepool_sa_iam_emails,
    "roles/stackdriver.resourceMetadata.writer" = local.list_nodepool_sa_iam_emails,
    "roles/artifactregistry.reader"             = local.list_nodepool_sa_iam_emails,
  }

  depends_on = [
    module.project-services
  ]
}

module "fl-workload-identity" {
  for_each   = local.tenants
  source     = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version    = "26.1.1"
  project_id = data.google_project.project.project_id

  annotate_k8s_sa     = false
  k8s_sa_name         = "ksa"
  location            = module.gke.location
  name                = module.service_accounts.service_accounts_map[each.value.tenant_apps_sa_name].account_id
  namespace           = each.key
  use_existing_gcp_sa = true
  use_existing_k8s_sa = true

  # The workload identity pool must exist before binding
  module_depends_on = [
    module.gke
  ]

}
