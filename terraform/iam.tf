# Service Account used by the nodes in a tenant node pool
resource "google_service_account" "tenant_nodepool_sa" {
  for_each     = local.tenants
  project      = data.google_project.project.project_id
  account_id   = each.value.tenant_nodepool_sa_name
  display_name = "Service account for ${each.key} node pool in cluster ${var.cluster_name}"

  depends_on = [
    module.project-services
  ]
}

# Service Account used by the nodes in the main node pool
resource "google_service_account" "main_nodepool_sa" {
  project      = data.google_project.project.project_id
  account_id   = local.main_node_pool_sa_name
  display_name = "Service account for ${local.main_node_pool_name} node pool in cluster ${var.cluster_name}"

  depends_on = [
    module.project-services
  ]
}

# Service Account used by apps in a tenant namespace
resource "google_service_account" "tenant_apps_sa" {
  for_each     = local.tenants
  project      = data.google_project.project.project_id
  account_id   = each.value.tenant_apps_sa_name
  display_name = "Service account for ${each.key} apps in cluster ${var.cluster_name}"

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
