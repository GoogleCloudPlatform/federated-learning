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

resource "null_resource" "copy_common_acm_content" {
  triggers = {
    create_command      = local.copy_acm_common_content_command
    create_script_hash  = md5(file(local.copy_acm_common_content_script_path))
    destroy_command     = local.delete_acm_common_content_command
    destroy_script_hash = md5(file(local.delete_acm_common_content_script_path))

    source_contents_hash      = local.acm_config_sync_common_content_source_content_hash
    destination_contents_hash = local.acm_config_sync_common_content_destination_content_hash

    # Always run this. We check if something needs to be done in the creation script
    timestamp = timestamp()
  }

  provisioner "local-exec" {
    when    = create
    command = self.triggers.create_command
  }

  provisioner "local-exec" {
    when    = destroy
    command = self.triggers.destroy_command
  }
}

resource "null_resource" "tenant_configuration" {
  for_each = local.tenants_excluding_main

  triggers = {
    create_command      = <<-EOT
      "${local.generate_and_copy_acm_tenant_content_script_path}" \
        "${local.acm_config_sync_tenants_configuration_destination_directory_path}" \
        "${local.acm_config_sync_tenant_configuration_package_source_directory_path}" \
        "${each.value.tenant_name}" \
        "${module.service_accounts.service_accounts_map[each.value.tenant_apps_sa_name].email}" \
        "${local.tenant_developer_example_account}" \
        "${each.value.distributed_tff_example_deploy}" \
        "${local.distributed_tff_example_package_source_directory_path}" \
        "${each.value.distributed_tff_example_is_coordinator}" \
        "${each.value.distributed_tff_example_worker_emnist_partition_file_name}" \
        "${each.value.distributed_tff_example_is_coordinator && local.distributed_tff_example_are_workers_outside_the_coordinator_mesh ? local.distributed_tff_example_worker_1_external_fqdn : each.value.distributed_tff_example_worker_1_hostname}" \
        "${each.value.distributed_tff_example_is_coordinator && local.distributed_tff_example_are_workers_outside_the_coordinator_mesh ? local.distributed_tff_example_worker_2_external_fqdn : each.value.distributed_tff_example_worker_2_hostname}" \
        "${each.value.tenant_apps_kubernetes_service_account_name}" \
        "${var.distributed_tff_example_coordinator_namespace}" \
        "${!each.value.distributed_tff_example_is_coordinator && var.distributed_tff_example_deploy_ingress_gateway}" \
        "${local.distributed_tff_example_are_workers_outside_the_coordinator_mesh}" \
        "${each.value.distributed_tff_example_deploy ? "${local.container_image_repository_fully_qualified_hostname}/${local.container_image_repository_name}/tff-runtime:0.0.1" : "${local.container_image_repository_fully_qualified_hostname}/${local.container_image_repository_name}/tff-runtime:0.0.1"}"
    EOT
    create_script_hash  = md5(file(local.generate_and_copy_acm_tenant_content_script_path))
    destroy_command     = <<-EOT
      "${local.delete_acm_tenant_content_script_path}" \
        "${local.acm_config_sync_tenants_configuration_destination_directory_path}/${each.value.tenant_name}"
    EOT
    destroy_script_hash = md5(file(local.delete_acm_tenant_content_script_path))

    source_contents_hash                                 = local.acm_config_sync_tenant_configuration_package_source_content_hash
    distributed_tff_example_package_source_contents_hash = each.value.distributed_tff_example_deploy ? local.distributed_tff_example_package_source_content_hash : ""
    distributed_tff_example_container_image_id           = each.value.distributed_tff_example_deploy ? "${local.container_image_repository_fully_qualified_hostname}/${local.container_image_repository_name}/tff-runtime:0.0.1" : ""

    # Always run this. We check if something needs to be done in the creation script
    timestamp = timestamp()
  }

  provisioner "local-exec" {
    when    = create
    command = self.triggers.create_command
  }

  provisioner "local-exec" {
    when    = destroy
    command = self.triggers.destroy_command
  }

  depends_on = [
    null_resource.copy_common_acm_content
  ]
}

resource "null_resource" "copy_mesh_wide_distributed_tff_example_content" {
  count = local.deploy_distributed_tff_example_any_tenant ? 1 : 0

  triggers = {
    source_contents_hash = local.distributed_tff_example_mesh_wide_source_content_hash

    # If the coordinator namespace is set to istio-ingress, we assume that workers are outside
    # the service mesh (example: in another cluster), so we need to deploy service entries
    # to make them reachable from the mesh.
    create_command      = <<-EOT
      "${local.copy_distributed_tff_example_mesh_wide_content_script_path}" \
        "${local.distributed_tff_example_mesh_wide_source_directory_path}" \
        "${local.distributed_tff_example_mesh_wide_destination_directory_path}" \
        "${var.distributed_tff_example_deploy_ingress_gateway}" \
        "${local.distributed_tff_example_are_workers_outside_the_coordinator_mesh}" \
        "${local.distributed_tff_example_is_there_a_coordinator}"
    EOT
    destroy_command     = <<-EOT
      "${local.delete_distributed_tff_example_mesh_wide_content_script_path}" \
        "${local.distributed_tff_example_mesh_wide_destination_directory_path}"
    EOT
    create_script_hash  = md5(file(local.copy_distributed_tff_example_mesh_wide_content_script_path))
    destroy_script_hash = md5(file(local.delete_distributed_tff_example_mesh_wide_content_script_path))

    # Always run this. We check if something needs to be done in the creation script
    timestamp = timestamp()
  }

  provisioner "local-exec" {
    when    = create
    command = self.triggers.create_command
  }

  provisioner "local-exec" {
    when    = destroy
    command = self.triggers.destroy_command
  }

  depends_on = [
    null_resource.copy_common_acm_content
  ]
}
