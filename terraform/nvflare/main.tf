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

data "google_project" "project" {
  project_id = var.project_id
}

module "buckets" {
  source     = "terraform-google-modules/cloud-storage/google"
  version    = "9.1.0"
  project_id = data.google_project.project.project_id
  location   = var.region
  prefix     = "fcp"
  names      = [var.workspace_bucket_name]
}
