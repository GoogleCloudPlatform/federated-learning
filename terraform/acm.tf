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

resource "google_gke_hub_membership" "membership" {
  membership_id = module.gke.name
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${module.gke.cluster_id}"
    }
  }
  provider = google-beta

  depends_on = [
    module.project-services
  ]
}

resource "google_gke_hub_feature" "feature" {
  name     = "configmanagement"
  location = "global"
  provider = google-beta

  depends_on = [
    module.project-services
  ]
}

resource "google_gke_hub_feature_membership" "feature_member" {
  location   = "global"
  feature    = google_gke_hub_feature.feature.name
  membership = google_gke_hub_membership.membership.membership_id
  configmanagement {
    version = var.acm_version
    config_sync {
      git {
        sync_repo   = var.acm_repo_location
        sync_branch = var.acm_branch
        policy_dir  = var.acm_dir
        secret_type = var.acm_secret_type
      }
      source_format = "unstructured"
    }
    # Note that we enable PolicyController mutations separately below
    policy_controller {
      enabled                    = true
      mutation_enabled           = true
      template_library_installed = true
    }
  }
  provider = google-beta

  depends_on = [
    module.asm.asm_wait,
  ]
}
