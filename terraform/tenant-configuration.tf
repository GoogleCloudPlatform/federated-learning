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
    md5                 = md5(google_sourcerepo_repository.configsync-repository.url)
    acm_branch          = var.acm_branch
    acm_repository_path = var.acm_repository_path
  }

  provisioner "local-exec" {
    when    = create
    command = <<-EOT
      mkdir -p "${var.acm_repository_path}"
      git clone "${google_sourcerepo_repository.configsync-repository.url}" "${self.triggers.acm_repository_path}"
      git -C "${self.triggers.acm_repository_path}" config pull.ff only
      git -C "${self.triggers.acm_repository_path}" config user.email "committer@example.com"
      git -C "${self.triggers.acm_repository_path}" config user.name "Config Sync committer"
      git -C "${self.triggers.acm_repository_path}" checkout -b "${self.triggers.acm_branch}"
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      rm -rf "${self.triggers.acm_repository_path}"
    EOT
  }
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
