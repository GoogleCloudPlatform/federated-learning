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
  default     = false
}

variable "list_apps_sa_iam_emails" {
  description = "List of SA to add roles to when deploying cross-device workload"
  type        = list(string)
}

variable "odp_image_version" {
  description = "Version tag for ODP service images"
  type        = string
  default     = "latest"
}

variable "odp_enable_monitoring" {
  description = "Enable monitoring for ODP services"
  type        = bool
  default     = true
}

variable "odp_java_memory_limit" {
  description = "Memory limit for Java services"
  type        = string
  default     = "3Gi"
}

variable "odp_java_memory_request" {
  description = "Memory request for Java services"
  type        = string
  default     = "2Gi"
}

variable "deploy_services" {
  description = "Whether to deploy the ODP services within the cross-device module"
  type        = bool
  default     = false
}

# Add Spanner-related variables
variable "spanner_instance_name" {
  description = "Name of the Spanner instance"
  type        = string
  default     = "odp-federated-compute"
}

variable "spanner_database_name" {
  description = "Name of the Spanner database"
  type        = string
  default     = "odp-federated-compute"
}

variable "spanner_nodes" {
  description = "Number of nodes for Spanner instance"
  type        = number
  default     = 1
}

variable "aggregator_sa" {
  description = "The Kubernetes service account name for task management"
  type        = string
}

variable "collector_sa" {
  description = "The Kubernetes service account name for task management"
  type        = string
}

variable "task_management_sa" {
  description = "The Kubernetes service account name for task management"
  type        = string
}

variable "model_updater_sa" {
  description = "The Kubernetes service account name for model training"
  type        = string
}

variable "task_assignment_sa" {
  description = "The Kubernetes service account name for model evaluation"
  type        = string
}

variable "task_scheduler_sa" {
  description = "The Kubernetes service account name for model aggregation"
  type        = string
}

variable "aggregator_image" {
  description = "The container image for task management"
  type        = string
}

variable "collector_image" {
  description = "The container image for task management"
  type        = string
}

variable "model_updater_image" {
  description = "The container image for task management"
  type        = string
}

variable "task_assignment_image" {
  description = "The container image for task management"
  type        = string
}

variable "task_management_image" {
  description = "The container image for task management"
  type        = string
}

variable "task_scheduler_image" {
  description = "The container image for task management"
  type        = string
}
