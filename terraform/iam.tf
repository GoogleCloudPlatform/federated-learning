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

# There's no Terraform module for Cloud Source Repositories bindings, so we
# configure it directly
resource "google_sourcerepo_repository_iam_binding" "binding" {
  project    = google_sourcerepo_repository.my-repo.project
  repository = google_sourcerepo_repository.configsync-repository.name

  role = "roles/viewer"

  members = [
    local.source_repository_service_account_iam_email,
  ]
}

module "fl-workload-identity" {
  for_each   = local.tenants
  source     = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version    = "27.0.0"
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
