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

  main_tenant_name = "main"

  # To reduce duplication, treat the main pool as the first (privileged) tenant
  tenant_and_main_pool_names = concat(
    [local.main_tenant_name],
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
