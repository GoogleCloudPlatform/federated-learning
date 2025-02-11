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

module "project-iam-bindings" {
  source   = "terraform-google-modules/iam/google//modules/projects_iam"
  version  = "8.0.0"
  projects = [data.google_project.project.project_id]

  bindings = {
    "roles/spanner.admin"                  = var.list_apps_sa_iam_emails,
    "roles/logging.logWriter"              = var.list_apps_sa_iam_emails,
    "roles/iam.serviceAccountTokenCreator" = var.list_apps_sa_iam_emails,
    "roles/storage.objectAdmin"            = var.list_apps_sa_iam_emails,
    "roles/pubsub.admin"                   = var.list_apps_sa_iam_emails
  }
}

# Create Kubernetes Service Accounts
resource "kubernetes_service_account" "ksa" {
  for_each = local.odp_services
  metadata {
    name      = var.task_management_sa
    namespace = "default"
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.odp_services[each.key].email
    }
  }
}

# Set up Workload Identity bindings
resource "google_service_account_iam_binding" "ksa_workload_identity" {
  for_each           = local.odp_services
  service_account_id = google_service_account.odp_services[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[default/${each.value.service_account_name}]"
  ]
}
