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

module "acm" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/acm"
  version = "27.0.0"

  project_id   = data.google_project.project.project_id
  cluster_name = module.gke.name
  location     = module.gke.location

  configmanagement_version  = var.acm_version
  create_metrics_gcp_sa     = true
  enable_mutation           = true
  gcp_service_account_email = local.source_repository_service_account_email
  policy_dir                = var.acm_dir
  secret_type               = "gcpServiceAccount"
  source_format             = "unstructured"
  sync_repo                 = google_sourcerepo_repository.configsync-repository.url
  sync_branch               = var.acm_branch

  depends_on = [
    module.asm.asm_wait,
    module.gke,
    module.project-services
  ]
}
