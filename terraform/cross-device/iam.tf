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

locals {
  service_accounts = [
    var.task_assignment_sa,
    var.task_management_sa,
    var.task_scheduler_sa,
    var.collector_sa
  ]

  list_sa_iam_emails = [for sa in local.service_accounts : "serviceAccount:${module.service_accounts.service_accounts_map[sa].email}"]
}

module "service_accounts" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.5.0"
  project_id = data.google_project.project.project_id

  grant_billing_role = false
  grant_xpn_roles    = false
  names              = local.service_accounts

  depends_on = [
    module.project-services
  ]
}

module "project-iam-bindings" {
  source   = "terraform-google-modules/iam/google//modules/projects_iam"
  version  = "8.0.0"
  projects = [data.google_project.project.project_id]
  mode     = "authoritative"

  bindings = {
    # Least-privilege roles needed for a node pool service account to function and
    # to get read-only access to Container Registry and Artifact Registry
    "roles/spanner.databaseUser"                   = local.list_sa_iam_emails,
    "roles/logging.logWriter" = local.list_sa_iam_emails,
    "roles/iam.serviceAccountTokenCreator" = local.list_sa_iam_emails,
    "roles/storage.objectUser"             = local.list_sa_iam_emails,
    "roles/pubsub.subscriber" = local.list_sa_iam_emails,
    "roles/gkehub.serviceAgent"            = local.list_sa_iam_emails,
    "roles/iam.workloadIdentityUser"             = local.list_sa_iam_emails,
    "roles/pubsub.publisher"                   = local.list_sa_iam_emails,
    "roles/secretmanager.secretAccessor"        = local.list_sa_iam_emails
  }

  depends_on = [
    module.project-services
  ]
}

module "fl-workload-identity" {
  for_each   = toset(local.service_accounts)
  source     = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version    = "35.0.1"
  project_id = data.google_project.project.project_id

  annotate_k8s_sa     = false
  k8s_sa_name         = each.value
  location            = var.region
  name                = module.service_accounts.service_accounts_map[each.value].account_id
  namespace           = local.odp_namespace
  use_existing_gcp_sa = true
  use_existing_k8s_sa = false

  depends_on = [
    # Wait for the service accounts to be ready before trying to load data about them
    # Ref: https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/issues/1059
    module.service_accounts
  ]
}
