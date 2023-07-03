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

# See the series of blog posts for details on enabling Anthos Config Management using Terraform
# https://cloud.google.com/blog/topics/anthos/using-terraform-to-enable-config-sync-on-a-gke-cluster
module "acm" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/acm"
  version = "27.0.0"

  project_id   = data.google_project.project.project_id
  cluster_name = module.gke.name
  location     = module.gke.location

  configmanagement_version = var.acm_version
  create_metrics_gcp_sa    = true
  enable_mutations         = true
  policy_dir               = var.acm_dir
  secret_type              = var.acm_secret_type
  source_format            = "unstructured"
  sync_repo                = var.acm_repo_location
  sync_branch              = var.acm_branch


  depends_on = [
    module.gke,
    module.project-services
  ]
}
