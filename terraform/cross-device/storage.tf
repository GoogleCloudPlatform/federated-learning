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

# Note: name max length = 63
module "buckets" {
  source     = "terraform-google-modules/cloud-storage/google"
  version    = "5.0.0"
  project_id = data.google_project.project.project_id
  location   = var.region
  prefix     = "fcp-${var.environment}"
  names      = ["m-0", "a-0", "g-0"]
  force_destroy = {
    m-0 = var.model_bucket_force_destroy,
    a-0 = var.aggregated_gradient_bucket_force_destroy
    g-0 = var.client_gradient_bucket_force_destroy
  }
  versioning = {
    m-0 = var.model_bucket_versioning
    a-0 = var.aggregated_gradient_bucket_versioning
    g-0 = var.client_gradient_bucket_versioning
  }
  public_access_prevention = "enforced"
  bucket_policy_only = {
    m-0 = true
    a-0 = true
    g-0 = true
  }
  lifecycle_rules = [{
    action = {
      type = "Delete"
    }
    condition = {
      age = 60 # days
    }
    }, {
    action = {
      type = "Delete"
    }
    condition = {
      days_since_noncurrent_time = 10
    }
  }]
}
