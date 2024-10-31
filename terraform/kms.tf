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

module "kms" {
  source  = "terraform-google-modules/kms/google"
  version = "3.2.0"

  project_id = data.google_project.project.project_id
  location   = var.region
  keyring    = "keyring-${random_id.keyring_suffix.hex}"
  keys       = [var.cluster_secrets_keyname]

  # IAM
  set_encrypters_for = [var.cluster_secrets_keyname]
  set_decrypters_for = [var.cluster_secrets_keyname]
  encrypters         = ["serviceAccount:${local.gke_robot_sa}"]
  decrypters         = ["serviceAccount:${local.gke_robot_sa}"]
  prevent_destroy    = false

  depends_on = [
    module.project-services
  ]
}

# KeyRings cannot be deleted; append a suffix to name
resource "random_id" "keyring_suffix" {
  byte_length = 4
}
