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

variable "acm_repository_path" {
  description = "Path to the directory that will contain the Config Management repositories on the local machine"
  type        = string
}

variable "organizations_count" {
  default     = 3
  description = "Number of simulated organizations to provision"
  type        = number
}

variable "project_id" {
  description = "The Google Cloud project ID"
  type        = string
}

variable "region" {
  default     = "europe-west1"
  description = "The region for clusters"
  type        = string
}
