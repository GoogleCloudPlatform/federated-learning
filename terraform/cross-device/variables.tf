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

variable "collector_sa" {
  description = "The Kubernetes service account name for task management"
  type        = string
}

variable "task_management_sa" {
  description = "The Kubernetes service account name for task management"
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

# Aggregator parameters
variable "aggregator_instance_source_image" {
  description = "The aggregator OS source container image to run."
  type        = string
  default     = "projects/confidential-space-images/global/images/confidential-space-debug-250100"
}

variable "aggregator_machine_type" {
  description = "The aggregator machine type of the VM."
  type        = string
  default     = "n2d-standard-8"
}

variable "aggregator_autoscaling_jobs_per_instance" {
  description = "The ratio of jobs to aggregator worker instances to scale by."
  type        = number
  default     = 2
}

variable "aggregator_max_replicas" {
  description = "The maximum number of aggregator instances that the autoscaler can scale up to. "
  type        = number
  default     = 5
}

variable "aggregator_min_replicas" {
  description = "The minimum number of aggregator replicas that the autoscaler can scale down to."
  type        = number
  default     = 2
}

variable "aggregator_cooldown_period" {
  description = "The number of seconds that the autoscaler should wait before it starts collecting information from a aggregator new instance."
  type        = number
  default     = 180
}

variable "aggregator_subscriber_max_outstanding_element_count" {
  description = "The maximum number of messages for the aggregator which have not received acknowledgments or negative acknowledgments before pausing the stream."
  type        = number
  default     = 2
}

# ModelUpdater parameters
variable "model_updater_instance_source_image" {
  description = "The model_updater OS source container image to run."
  type        = string
  default     = "projects/confidential-space-images/global/images/confidential-space-debug-250100"
}

variable "model_updater_machine_type" {
  description = "The model_updater machine type of the VM."
  type        = string
  default     = "n2d-standard-8"
}

variable "model_updater_autoscaling_jobs_per_instance" {
  description = "The ratio of jobs to model_updater worker instances to scale by."
  type        = number
  default     = 2
}

variable "model_updater_max_replicas" {
  description = "The maximum number of model_updater instances that the autoscaler can scale up to. "
  type        = number
  default     = 5
}

variable "model_updater_min_replicas" {
  description = "The minimum number of model_updater replicas that the autoscaler can scale down to."
  type        = number
  default     = 2
}

variable "model_updater_cooldown_period" {
  description = "The number of seconds that the autoscaler should wait before it starts collecting information from a model_updater new instance."
  type        = number
  default     = 120
}

variable "model_updater_subscriber_max_outstanding_element_count" {
  description = "The maximum number of messages for the model updater which have not received acknowledgments or negative acknowledgments before pausing the stream."
  type        = number
  default     = 2
}

variable "allowed_operator_service_accounts" {
  description = "The service accounts provided by coordinator for the worker to impersonate."
  type        = string
}

variable "network_name" {

}

variable "subnet_name" {

}

# Service input variables
variable "encryption_key_service_a_base_url" {
  description = "The base url of the encryption key service A."
  type        = string
}

variable "encryption_key_service_b_base_url" {
  description = "The base url of the encryption key service B."
  type        = string
}

variable "encryption_key_service_a_cloudfunction_url" {
  description = "The cloudfunction url of the encryption key service A."
  type        = string
}

variable "encryption_key_service_b_cloudfunction_url" {
  description = "The cloudfunction url of the encryption key service B."
  type        = string
}

variable "wip_provider_a" {
  description = "The workload identity provider of the encryption key service A."
  type        = string
}

variable "wip_provider_b" {
  description = "The workload identity provider of the encryption key service B."
  type        = string
}

variable "service_account_a" {
  description = "The service account to impersonate of the encryption key service A."
  type        = string
}

variable "service_account_b" {
  description = "The service account to impersonate of the encryption key service B."
  type        = string
}

variable "aggregator_compute_service_account" {

}


variable "model_updater_compute_service_account" {

}

variable "download_plan_token_duration" {
  description = "Duration in seconds the download plan signed URL token is valid for"
  type        = number
  default = 900
}

variable "download_checkpoint_token_duration" {
  description = "Duration in seconds the download checkpoint signed URL token is valid for"
  type        = number
  default = 900
}

variable "upload_gradient_token_duration" {
  description = "Duration in seconds the upload gradient signed URL token is valid for"
  type        = number
  default = 900
}

variable "allow_rooted_devices" {
  description = "Whether to allow rooted devices. This setting will have no effect when authentication is disabled. It is recommended to be set false for production environments."
  type        = bool
  default     = false
}

variable "is_authentication_enabled" {
  description = "Whether to enable authentication"
  type        = bool
  default     = false
}

variable "local_compute_timeout_minutes" {
  description = "The duration an assignment will remain in ASSIGNED status before timing out in minutes."
  type        = number
  default     = 15
}

variable "upload_timeout_minutes" {
  description = "The duration an assignment will remain in LOCAL_COMPLETED status before timing out in minutes."
  type        = number
  default     = 15
}

variable "aggregation_batch_failure_threshold" {
  description = "The number of aggregation batches failed for an iteration before moving the iteration to a failure state."
  type        = number
  default     = 3
}

variable "collector_batch_size" {
  description = "The size of aggregation batches created by the collector"
  type        = number
  default     = 50
}
