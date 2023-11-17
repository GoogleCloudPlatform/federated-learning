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

variable "environment" {
  description = "Description for the environment, e.g. dev, staging, production."
  type        = string
  default     = "demo-dev"
}

variable "project_id" {
  description = "Google Cloud Project ID in which this module will be created."
  type        = string
}

variable "region" {
  description = "Region where regional resources will be created."
  type        = string
}

variable "model_bucket_force_destroy" {
  description = "Enable to force destroy the model bucket even if it is not empty."
  type        = bool
  default     = false
}

variable "model_bucket_versioning" {
  description = "Enable model bucket versioning."
  type        = bool
  default     = false
}

variable "client_gradient_bucket_force_destroy" {
  description = "Enable to force destroy the client gradient bucket even if it is not empty."
  type        = bool
  default     = false
}

variable "client_gradient_bucket_versioning" {
  description = "Enable client gradient bucket versioning."
  type        = bool
  default     = false
}

variable "aggregated_gradient_bucket_force_destroy" {
  description = "Enable to force destroy the aggregated gradient bucket even if it is not empty."
  type        = bool
  default     = false
}

variable "aggregated_gradient_bucket_versioning" {
  description = "Enable aggregated gradient bucket versioning."
  type        = bool
  default     = false
}

variable "spanner_database_retention_period" {
  description = "Duration to maintain table versioning for point-in-time recovery."
  type        = string
  nullable    = false
  default     = "1h"
}

variable "spanner_instance_config" {
  description = "Multi region config value for the Spanner Instance. Example: 'nam10' for North America."
  type        = string
}

variable "spanner_processing_units" {
  description = "Spanner's compute capacity. 1000 processing units = 1 node and must be set as a multiple of 100."
  type        = number
}

variable "spanner_database_deletion_protection" {
  description = "Prevents destruction of the Spanner database."
  type        = bool
}

variable "google_service_account" {
  description = "Google Cloud Service Account for Workload Identity"
  type        = string
}
