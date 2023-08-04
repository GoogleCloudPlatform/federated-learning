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

module "asm" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/asm"
  version = "27.0.0"

  channel             = var.asm_release_channel
  cluster_location    = module.gke.location
  cluster_name        = module.gke.name
  project_id          = data.google_project.project.project_id
  enable_mesh_feature = var.asm_enable_mesh_feature
}

# This is needed until https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/pull/1702
# is merged, and we update to a ASM module release that includes that.
resource "google_gke_hub_feature_membership" "mesh_feature_membership" {
  count = var.asm_enable_mesh_feature ? 1 : 0

  location   = "global"
  feature    = "servicemesh"
  membership = "${module.gke.name}-membership"
  mesh {
    management = "MANAGEMENT_AUTOMATIC"
  }
  provider = google-beta
}
