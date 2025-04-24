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

resource "google_gke_hub_feature" "policy_controller_feature" {
  name     = "policycontroller"
  location = "global"

  depends_on = [
    module.project-services
  ]
}

resource "google_gke_hub_feature_membership" "policy_controller_feature_member" {
  location   = google_gke_hub_feature.policy_controller_feature.location
  feature    = google_gke_hub_feature.policy_controller_feature.name
  membership = google_gke_hub_membership.membership.membership_id
  policycontroller {
    policy_controller_hub_config {
      policy_content {
        template_library {
          installation = "ALL"
        }
        bundles {
          bundle_name = "asm-policy-v0.0.1"
        }
      }
      audit_interval_seconds    = 60
      install_spec              = "INSTALL_SPEC_ENABLED"
      log_denies_enabled        = true
      mutation_enabled          = true
      referential_rules_enabled = true
    }
  }
}
