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

resource "null_resource" "init_acm_repository" {
  triggers = {
    md5                               = md5(local.init_local_acm_repository_command)
    acm_repository_path               = var.acm_repository_path
    init_local_acm_repository_command = local.init_local_acm_repository_command
    script_md5                        = md5(file(local.init_local_acm_repository_script_path))
  }

  provisioner "local-exec" {
    when    = create
    command = self.triggers.init_local_acm_repository_command
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      rm -rf "${self.triggers.acm_repository_path}"
    EOT
  }
}

resource "null_resource" "copy_common_acm_content" {
  triggers = {
    md5                             = md5(local.copy_acm_common_content_command)
    source_contents_hash            = sha512(join("", [for f in fileset(local.acm_config_sync_common_content_source_path, "*") : filesha512(f)]))
    copy_acm_common_content_command = local.copy_acm_common_content_command
    script_md5                      = md5(file(local.copy_acm_common_content_script_path))
  }

  provisioner "local-exec" {
    when    = create
    command = self.triggers.copy_acm_common_content_command
  }

  # TODO: delete common content on destroy

  depends_on = [
    null_resource.init_acm_repository
  ]
}

# TODO: copy configsync directory

# resource "null_resource" "tenant_configuration" {
#   for_each = local.tenants

#   triggers = merge({
#     md5                          = md5(var.create_cmd_entrypoint)
#     arguments                    = md5(var.create_cmd_body)
#     create_cmd_entrypoint        = var.create_cmd_entrypoint
#     create_cmd_body              = var.create_cmd_body
#     kpt_evaluate_package_command = local.kpt_evaluate_package_command
#   }, var.create_cmd_triggers)

#   provisioner "local-exec" {
#     when    = create
#     command = "${self.triggers.kpt_evaluate_package_command} ${each.key} ${module.service_accounts.service_accounts_map[each.value.tenant_apps_sa_name].account_id} ${local.tenant_developer_example_account}"
#   }

#   # TODO: destroy command deletes the tenant directory

#   depends_on = [
#     null_resource.module_depends_on,
#     null_resource.decompress,
#     null_resource.additional_components,
#     null_resource.gcloud_auth_google_credentials,
#     null_resource.gcloud_auth_service_account_key_file
#   ]

# }

# TODO: commit changes (even on deletions)
