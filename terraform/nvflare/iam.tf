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

module "storage_bucket_iam_bindings" {
  source          = "terraform-google-modules/iam/google//modules/storage_buckets_iam"
  version         = "8.1.0"
  storage_buckets = ["fcp-${var.workspace_bucket_name}"]

  bindings = {
    "roles/storage.objectUser" = var.list_apps_sa_iam_emails
  }
}
