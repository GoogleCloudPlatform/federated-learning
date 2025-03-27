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

  list_confidential_space_sa = [
    var.aggregator_sa,
    var.model_updater_sa
  ]

  list_confidential_space_sa_iam_emails = [for sa in local.list_confidential_space_sa : "serviceAccount:${module.service_accounts.service_accounts_map[local.list_confidential_space_sa[index(local.list_confidential_space_sa, sa)]].email}"]

  tenants = {
    for name in local.tenant_and_main_pool_names : name => {
      tenant_name                                 = name
      tenant_nodepool_name                        = format("%s-pool", name)
      tenant_nodepool_sa_name                     = format("%s-%s-nodes-sa", var.cluster_name, name)
      tenant_apps_sa_name                         = format("%s-%s-apps-sa", var.cluster_name, name)
      tenant_apps_kubernetes_service_account_name = local.tenant_apps_kubernetes_service_account_name
    }
  }

  tenant_apps_kubernetes_service_account_name = "ksa"

  tenants_excluding_main = { for k, v in local.tenants : k => v if k != local.main_tenant_name }

  gke_robot_sa = "service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com"

  # We can't use module.service_accounts.emails because of
  # https://github.com/terraform-google-modules/terraform-google-service-accounts/issues/59
  list_nodepool_sa_emails = [for tenant in local.tenants : module.service_accounts.service_accounts_map[tenant.tenant_nodepool_sa_name].email]

  # We can't use module.service_accounts.iam_emails because of
  # https://github.com/terraform-google-modules/terraform-google-service-accounts/issues/59
  list_nodepool_sa_iam_emails = [for tenant in local.tenants : "serviceAccount:${module.service_accounts.service_accounts_map[tenant.tenant_nodepool_sa_name].email}"]

  list_apps_sa_iam_emails = {
    for tenant in local.tenants : tenant.tenant_name => [
      "serviceAccount:${module.service_accounts.service_accounts_map[tenant.tenant_apps_sa_name].email}"
    ]
  }

  list_sa_names = concat(
    [for tenant in local.tenants : tenant.tenant_nodepool_sa_name],
    [for tenant in local.tenants : tenant.tenant_apps_sa_name]
  )

  acm_config_sync_tenant_configuration_package_source_directory_path = abspath("${path.module}/../tenant-config-pkg")

  acm_config_sync_destination_directory_path                       = "${var.acm_repository_path}/${var.acm_dir}"
  acm_config_sync_tenants_configuration_destination_directory_path = "${local.acm_config_sync_destination_directory_path}/tenants"

  acm_config_sync_common_content_destination_content_hash = sha512(join("", [for f in local.acm_config_sync_common_content_destination_fileset : fileexists(f) ? filesha512(f) : sha512("file-not-found")]))
  acm_config_sync_common_content_destination_fileset      = [for f in local.acm_config_sync_common_content_source_fileset : replace(f, local.acm_config_sync_common_content_source_directory_path, local.acm_config_sync_destination_directory_path)]
  acm_config_sync_common_content_source_content_hash      = sha512(join("", [for f in local.acm_config_sync_common_content_source_fileset : filesha512(f)]))
  acm_config_sync_common_content_source_fileset           = [for f in fileset(local.acm_config_sync_common_content_source_directory_path, "**") : "${local.acm_config_sync_common_content_source_directory_path}/${f}"]
  acm_config_sync_common_content_source_directory_path    = abspath("${path.module}/../configsync")

  acm_config_sync_tenant_configuration_source_fileset              = [for f in fileset(local.acm_config_sync_tenant_configuration_package_source_directory_path, "**") : "${local.acm_config_sync_tenant_configuration_package_source_directory_path}/${f}"]
  acm_config_sync_tenant_configuration_package_source_content_hash = sha512(join("", [for f in local.acm_config_sync_tenant_configuration_source_fileset : filesha512(f)]))

  delete_fileset_script_path = abspath("${path.module}/scripts/delete-fileset.sh")

  copy_acm_common_content_script_path = abspath("${path.module}/scripts/copy-acm-common-content.sh")
  copy_acm_common_content_command     = <<-EOT
    "${local.copy_acm_common_content_script_path}" \
      "${local.acm_config_sync_common_content_source_directory_path}" \
      "${var.acm_repository_path}"
  EOT

  delete_acm_common_content_script_path = local.delete_fileset_script_path
  delete_acm_common_content_command     = <<-EOT
    "${local.delete_acm_common_content_script_path}" \
      "${join(" ", [for f in local.acm_config_sync_common_content_destination_fileset : f])}"
  EOT

  generate_and_copy_acm_tenant_content_script_path = abspath("${path.module}/scripts/generate-copy-acm-tenant-content.sh")

  delete_acm_tenant_content_script_path = local.delete_fileset_script_path

  # Temporary placeholder
  tenant_developer_example_account = "someuser@example.com"
}

data "google_project" "project" {
  project_id = var.project_id

  depends_on = [
    module.project-services
  ]
}

data "google_client_config" "default" {}

module "cross_device" {
  count                                      = var.cross_device ? 1 : 0
  source                                     = "./cross-device"
  project_id                                 = var.project_id
  region                                     = var.region
  spanner_instance_config                    = var.spanner_instance_config
  spanner_processing_units                   = var.spanner_processing_units
  list_apps_sa_iam_emails                    = local.list_apps_sa_iam_emails[var.cross_device_workloads_kubernetes_namespace]
  collector_sa                               = var.collector_sa
  task_management_sa                         = var.task_management_sa
  task_assignment_sa                         = var.task_assignment_sa
  task_scheduler_sa                          = var.task_scheduler_sa
  task_builder_sa                            = var.task_builder_sa
  aggregator_image                           = var.aggregator_image
  model_updater_image                        = var.model_updater_image
  collector_image                            = var.collector_image
  task_management_image                      = var.task_management_image
  task_assignment_image                      = var.task_assignment_image
  task_scheduler_image                       = var.task_scheduler_image
  task_builder_image                         = var.task_builder_image
  allowed_operator_service_accounts          = var.allowed_operator_service_accounts
  network_name                               = module.fedlearn-vpc.network_name
  subnet_name                                = local.fedlearn_subnet_name
  encryption_key_service_a_base_url          = var.encryption_key_service_a_base_url
  encryption_key_service_a_cloudfunction_url = var.encryption_key_service_a_cloudfunction_url
  encryption_key_service_b_base_url          = var.encryption_key_service_b_base_url
  encryption_key_service_b_cloudfunction_url = var.encryption_key_service_b_cloudfunction_url
  service_account_a                          = var.service_account_a
  service_account_b                          = var.service_account_b
  wip_provider_a                             = var.wip_provider_a
  wip_provider_b                             = var.wip_provider_b
  aggregator_compute_service_account         = module.service_accounts.service_accounts_map[var.aggregator_sa].email
  model_updater_compute_service_account      = module.service_accounts.service_accounts_map[var.model_updater_sa].email
}

module "nvflare" {
  count                   = var.nvflare ? 1 : 0
  source                  = "./nvflare"
  project_id              = data.google_project.project.id
  region                  = var.region
  workspace_bucket_name   = var.workspace_bucket_name
  list_apps_sa_iam_emails = local.list_apps_sa_iam_emails[var.nvflare_namespace]
}

module "distributed_tff_example" {
  count  = var.distributed_tff_example ? 1 : 0
  source = "./distributed-tff-example"

  distributed_tff_example_worker_1_address = var.distributed_tff_example_worker_1_address
  distributed_tff_example_worker_2_address = var.distributed_tff_example_worker_2_address
  list_nodepool_sa_emails                  = local.list_nodepool_sa_emails
  project_id                               = data.google_project.project.id
  vpc_network_id                           = module.fedlearn-vpc.network_id
  vpc_network_name                         = module.fedlearn-vpc.network_name
}
