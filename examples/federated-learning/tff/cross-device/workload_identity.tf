/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// TODO(b/293604392): Scope permissions
module "gke-workload-identity" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  name       = "${var.environment}-gke-wi"
  namespace  = "default"
  project_id = var.project_id
  roles      = ["roles/spanner.admin", "roles/logging.logWriter", "roles/iam.serviceAccountTokenCreator", "roles/storage.objectAdmin", "roles/pubsub.admin"]
}
