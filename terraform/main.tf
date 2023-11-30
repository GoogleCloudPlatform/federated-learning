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
      tenant_name                                 = name
      tenant_nodepool_name                        = format("%s-pool", name)
      tenant_nodepool_sa_name                     = format("%s-%s-nodes-sa", var.cluster_name, name)
      tenant_apps_sa_name                         = format("%s-%s-apps-sa", var.cluster_name, name)
      tenant_apps_kubernetes_service_account_name = local.tenant_apps_kubernetes_service_account_name

      # We can't use this variable in the following lines because we're still defining this object
      distributed_tff_example_deploy                            = var.distributed_tff_example_configuration != null && contains(keys(var.distributed_tff_example_configuration), name) ? true : false
      distributed_tff_example_is_coordinator                    = var.distributed_tff_example_configuration != null && contains(keys(var.distributed_tff_example_configuration), name) ? var.distributed_tff_example_configuration[name].is_coordinator : false
      distributed_tff_example_worker_1_hostname                 = var.distributed_tff_example_configuration != null && contains(keys(var.distributed_tff_example_configuration), name) ? var.distributed_tff_example_configuration[name].worker_1_hostname : ""
      distributed_tff_example_worker_2_hostname                 = var.distributed_tff_example_configuration != null && contains(keys(var.distributed_tff_example_configuration), name) ? var.distributed_tff_example_configuration[name].worker_2_hostname : ""
      distributed_tff_example_worker_emnist_partition_file_name = var.distributed_tff_example_configuration != null && contains(keys(var.distributed_tff_example_configuration), name) ? var.distributed_tff_example_configuration[name].emnist_partition_file_name : ""
    }
  }

  deploy_distributed_tff_example_flags      = [for tenant in local.tenants : tenant.distributed_tff_example_deploy]
  deploy_distributed_tff_example_any_tenant = anytrue(local.deploy_distributed_tff_example_flags) # Useful to know if we deployed the distributed TensorFlow Federated example in any namespace

  distributed_tff_example_is_there_a_coordinator_flags = [for tenant in local.tenants : tenant.distributed_tff_example_is_coordinator]
  distributed_tff_example_is_there_a_coordinator       = anytrue(local.distributed_tff_example_is_there_a_coordinator_flags) # Useful to know if we deployed a coordinator for the distributed TensorFlow Federated example in any namespace

  # If the coordinator namespace is set to istio-ingress, we assume that workers are outside the service mesh (example: in another cluster)
  distributed_tff_example_are_workers_outside_the_coordinator_mesh = var.distributed_tff_example_coordinator_namespace == "istio-ingress" ? true : false

  distributed_tff_example_external_domain        = "tensorflow-federated.example.com"
  distributed_tff_example_worker_1_hostname      = "tff-worker-1"
  distributed_tff_example_worker_2_hostname      = "tff-worker-2"
  distributed_tff_example_worker_1_external_fqdn = "${local.distributed_tff_example_worker_1_hostname}.${local.distributed_tff_example_external_domain}"
  distributed_tff_example_worker_2_external_fqdn = "${local.distributed_tff_example_worker_2_hostname}.${local.distributed_tff_example_external_domain}"

  tenant_apps_kubernetes_service_account_name = "ksa"

  tenants_excluding_main = { for k, v in local.tenants : k => v if k != local.main_tenant_name }

  gke_robot_sa = "service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com"

  # We can't use module.service_accounts.emails because of
  # https://github.com/terraform-google-modules/terraform-google-service-accounts/issues/59
  list_nodepool_sa_emails = [for tenant in local.tenants : module.service_accounts.service_accounts_map[tenant.tenant_nodepool_sa_name].email]

  # We can't use module.service_accounts.iam_emails because of
  # https://github.com/terraform-google-modules/terraform-google-service-accounts/issues/59
  list_nodepool_sa_iam_emails = [for tenant in local.tenants : "serviceAccount:${module.service_accounts.service_accounts_map[tenant.tenant_nodepool_sa_name].email}"]

  list_apps_sa_emails = [for tenant in local.tenants : module.service_accounts.service_accounts_map[tenant.tenant_apps_sa_name].email]
  list_apps_sa_iam_emails = {
    for tenant in local.tenants : tenant.tenant_name => [
      "serviceAccount:${module.service_accounts.service_accounts_map[tenant.tenant_apps_sa_name].email}"
    ]
  }

  list_sa_names = concat(
    [for tenant in local.tenants : tenant.tenant_nodepool_sa_name],
    [for tenant in local.tenants : tenant.tenant_apps_sa_name],
    [local.source_repository_service_account_name]
  )

  source_repository_service_account_id        = module.service_accounts.service_accounts_map[local.source_repository_service_account_name].account_id
  source_repository_service_account_name      = "fl-source-repository"
  source_repository_service_account_email     = module.service_accounts.service_accounts_map[local.source_repository_service_account_name].email
  source_repository_service_account_iam_email = "serviceAccount:${local.source_repository_service_account_email}"

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

  distributed_tff_example_source_directory_path         = abspath("${path.module}/../examples/federated-learning/tff/distributed-fl-simulation-k8s")
  distributed_tff_example_package_source_directory_path = "${local.distributed_tff_example_source_directory_path}/distributed-fl-workload-pkg"
  distributed_tff_example_package_source_fileset        = [for f in fileset(local.distributed_tff_example_package_source_directory_path, "**") : "${local.distributed_tff_example_package_source_directory_path}/${f}"]
  distributed_tff_example_package_source_content_hash   = sha512(join("", [for f in local.distributed_tff_example_package_source_fileset : filesha512(f)]))

  distributed_tff_example_mesh_wide_source_directory_path      = "${local.distributed_tff_example_source_directory_path}/mesh-wide"
  distributed_tff_example_mesh_wide_source_fileset             = [for f in fileset(local.distributed_tff_example_mesh_wide_source_directory_path, "**") : "${local.distributed_tff_example_mesh_wide_source_directory_path}/${f}"]
  distributed_tff_example_mesh_wide_source_content_hash        = sha512(join("", [for f in local.distributed_tff_example_mesh_wide_source_fileset : filesha512(f)]))
  distributed_tff_example_mesh_wide_destination_directory_path = "${local.acm_config_sync_destination_directory_path}/example-tff-image-classification-mesh-wide"

  distributed_tff_example_container_image_source_directory_path           = "${local.distributed_tff_example_source_directory_path}/container-image"
  distributed_tff_example_container_image_source_fileset                  = [for f in fileset(local.distributed_tff_example_container_image_source_directory_path, "**") : "${local.distributed_tff_example_container_image_source_directory_path}/${f}"]
  distributed_tff_example_container_image_source_descriptors_content_hash = sha512(join("", [for f in local.distributed_tff_example_container_image_source_fileset : filesha512(f)]))

  acm_config_sync_commit_configuration_script_path = abspath("${path.module}/scripts/commit-repository-changes.sh")

  delete_fileset_script_path = abspath("${path.module}/scripts/delete-fileset.sh")

  init_local_acm_repository_script_path = abspath("${path.module}/scripts/init-acm-repository.sh")

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

  copy_distributed_tff_example_mesh_wide_content_script_path   = abspath("${path.module}/scripts/copy-tff-example-mesh-wide-content.sh")
  delete_distributed_tff_example_mesh_wide_content_script_path = local.delete_fileset_script_path

  build_push_distributed_tff_example_container_image_script_path = abspath("${path.module}/scripts/build-push-container-image.sh")

  ditributed_tff_example_container_image_repository_hostname    = "${google_artifact_registry_repository.container_image_repository.location}-docker.pkg.dev"
  distributed_tff_example_container_image_repository_id         = "${local.ditributed_tff_example_container_image_repository_hostname}/${google_artifact_registry_repository.container_image_repository.project}/${google_artifact_registry_repository.container_image_repository.repository_id}"
  distributed_tff_example_localized_untagged_container_image_id = "${local.distributed_tff_example_container_image_repository_id}/tff-runtime"
  distributed_tff_example_localized_container_image_id          = "${local.distributed_tff_example_localized_untagged_container_image_id}:${local.distributed_tff_example_container_image_source_descriptors_content_hash}"

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

module "cross-device" {
  count                    = var.cross-device ? 1 : 0
  source                   = "./cross-device"
  project_id               = data.google_project.project.id
  region                   = var.region
  spanner_instance_config  = var.spanner_instance_config
  spanner_processing_units = var.spanner_processing_units
  list_apps_sa_iam_emails  = local.list_apps_sa_iam_emails[var.tenant_namespace]
}
