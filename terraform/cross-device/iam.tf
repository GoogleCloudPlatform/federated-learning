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
  service_accounts = {
    "task-management" = {
      k8s_name = var.task_management_sa
      gcp_name = var.task_management_sa
    }
    "task-assignment" = {
      k8s_name = var.task_assignment_sa
      gcp_name = var.task_assignment_sa
    }
    "collector" = {
      k8s_name = var.collector_sa
      gcp_name = var.collector_sa
    }
    "task-scheduler" = {
      k8s_name = var.task_scheduler_sa
      gcp_name = var.task_scheduler_sa
    }
  }
}

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
  for_each = local.service_accounts
  metadata {
    name      = each.value.k8s_name
    namespace = "default" # Changed from var.k8s_namespace_name to "default"
    annotations = {
      "iam.gke.io/gcp-service-account" = "${each.value.gcp_name}@${data.google_project.project.project_id}.iam.gserviceaccount.com"
    }
  }

  # Add lifecycle block to handle pre-existing resources
  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels,
    ]
  }
}

# Set up Workload Identity bindings
resource "google_service_account_iam_binding" "ksa_workload_identity" {
  for_each = local.service_accounts

  service_account_id = google_service_account.odp_services[each.key].name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[default/${each.value.k8s_name}]"
  ]
}

# Grant necessary roles to service accounts
resource "google_project_iam_member" "service_account_roles" {
  for_each = local.service_accounts
  project  = data.google_project.project.project_id
  role     = "roles/spanner.databaseUser"
  member   = "serviceAccount:${each.value.gcp_name}@${data.google_project.project.project_id}.iam.gserviceaccount.com"

  depends_on = [
    google_service_account.odp_services
  ]
}
