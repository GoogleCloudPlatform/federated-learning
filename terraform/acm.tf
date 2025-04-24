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

resource "google_gke_hub_feature" "acm_feature" {
  name     = "configmanagement"
  location = "global"

  depends_on = [
    module.project-services
  ]
}

resource "google_gke_hub_feature_membership" "acm_feature_member" {
  location   = google_gke_hub_feature.acm_feature.location
  feature    = google_gke_hub_feature.acm_feature.name
  membership = google_gke_hub_membership.membership.membership_id
  configmanagement {
    version = var.acm_version
    config_sync {
      enabled = true
      git {
        sync_repo   = var.acm_repository_url
        sync_branch = var.acm_branch
        policy_dir  = var.acm_dir
        secret_type = var.acm_secret_type
      }
      prevent_drift = true
      source_format = "unstructured"
    }
  }
}
