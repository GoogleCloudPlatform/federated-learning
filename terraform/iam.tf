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

# enable the tenant apps service accounts for Workload Identity
resource "google_service_account_iam_binding" "workload_identity" {
  for_each           = local.tenants
  service_account_id = module.service_accounts.service_accounts_map[each.value.tenant_apps_sa_name].name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    format("serviceAccount:%s.svc.id.goog[%s/ksa]", data.google_project.project.project_id, each.key),
  ]
  # workload identity pool must exist before binding
  depends_on = [
    module.gke
  ]
}
