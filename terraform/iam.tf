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
    # Least-privilege roles needed for a node pool service account to function
    "roles/logging.logWriter" = concat(
      [for service_account in google_service_account.tenant_nodepool_sa : format("serviceAccount:%s", service_account.email)],
      [format("serviceAccount:%s", google_service_account.main_nodepool_sa.email)]
    )
    "roles/monitoring.metricWriter" = concat(
      [for service_account in google_service_account.tenant_nodepool_sa : format("serviceAccount:%s", service_account.email)],
      [format("serviceAccount:%s", google_service_account.main_nodepool_sa.email)]
    )
    "roles/monitoring.viewer" = concat(
      [for service_account in google_service_account.tenant_nodepool_sa : format("serviceAccount:%s", service_account.email)],
      [format("serviceAccount:%s", google_service_account.main_nodepool_sa.email)]
    )
    "roles/stackdriver.resourceMetadata.writer" = concat(
      [for service_account in google_service_account.tenant_nodepool_sa : format("serviceAccount:%s", service_account.email)],
      [format("serviceAccount:%s", google_service_account.main_nodepool_sa.email)]
    )
    # Grant node pool service accounts read access to Container Registry and Artifact Registry
    "roles/artifactregistry.reader" = concat(
      [for service_account in google_service_account.tenant_nodepool_sa : format("serviceAccount:%s", service_account.email)],
      [format("serviceAccount:%s", google_service_account.main_nodepool_sa.email)]
    )
  }

  depends_on = [
    module.project-services
  ]
}

# enable the tenant apps service accounts for Workload Identity
resource "google_service_account_iam_binding" "workload_identity" {
  for_each           = google_service_account.tenant_apps_sa
  service_account_id = each.value.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    format("serviceAccount:%s.svc.id.goog[%s/ksa]", data.google_project.project.project_id, each.key),
  ]
  # workload identity pool must exist before binding
  depends_on = [
    module.gke
  ]
}
