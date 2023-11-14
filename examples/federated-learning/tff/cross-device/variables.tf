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

################################################################################
# Global Variables.
################################################################################
variable "project_id" {
  description = "GCP Project ID in which this module will be created."
  type        = string
}

variable "environment" {
  description = "Description for the environment, e.g. dev, staging, production"
  type        = string
}

variable "region" {
  description = "Region where all services will be created."
  type        = string
}

################################################################################
# Federated Learning images.
################################################################################
variable "taskmanagement_image" {
  description = "The taskmanagement container image."
  default     = "europe-west1-docker.pkg.dev/lgu-demos/federated-learning-cross-device/taskmanagement@sha256:0596c3d85d1c18110c4a69e694eb778d01fbb4248d831ab56a2a594cebc6bcec"
  type        = string
}

variable "taskmanagement_port" {
  description = "The taskmanagement service port."
  default     = "8082"
  type        = string
}

variable "taskassignment_image" {
  description = "The taskassignment container image."
  default     = "europe-west1-docker.pkg.dev/lgu-demos/federated-learning-cross-device/taskassignment@sha256:a5e0d81b51907bedcd679f9d64e73ea982aaf00d20c2bc7c7427f5b8a0eee4c8"
  type        = string
}

variable "taskassignment_port" {
  description = "The taskassignment service port."
  default     = "8083"
  type        = string
}

variable "taskscheduler_image" {
  description = "The taskscheduler container image."
  default     = "europe-west1-docker.pkg.dev/lgu-demos/federated-learning-cross-device/taskscheduler@sha256:30b0e17bd57d2952e9e73777d0fbdb1d1873c4b9c67b9f355ed75053839a62c8"
  type        = string
}

variable "modelupdater_image" {
  description = "The modelupdater container image."
  default     = "europe-west1-docker.pkg.dev/lgu-demos/federated-learning-cross-device/modelupdater@sha256:e3254cc6ffbd18cea9753dc6dc03403fd3eb1e2cb01a64e25b0d6db557fcc578"
  type        = string
}

variable "collector_image" {
  description = "The collector container image."
  default     = "europe-west1-docker.pkg.dev/lgu-demos/federated-learning-cross-device/collector@sha256:b4c692bacb4d1171ebcc49e96ad762969f966ea92fb2f7afc9e31a9c83e67c4d"
  type        = string
}

variable "static_ip_name" {
  description = "The static ip name"
  type        = string
}

variable "parent_domain_name" {
  description = "Custom domain name to register and use for external APIs."
  type        = string
}

// TODO(304845944): Expose this variable and pass in other resource names.
variable "token_duration" {
  type    = string
  default = 900
}

variable "model_bucket_force_destroy" {
  description = "Whether to force destroy the bucket even if it is not empty."
  type        = bool
  default     = false
}

variable "model_bucket_versioning" {
  description = "Enable bucket versioning."
  type        = bool
  default     = false
}

variable "client_gradient_bucket_force_destroy" {
  description = "Whether to force destroy the bucket even if it is not empty."
  type        = bool
  default     = false
}

variable "client_gradient_bucket_versioning" {
  description = "Enable bucket versioning."
  type        = bool
  default     = false
}

variable "aggregated_gradient_bucket_force_destroy" {
  description = "Whether to force destroy the bucket even if it is not empty."
  type        = bool
  default     = false
}

variable "aggregated_gradient_bucket_versioning" {
  description = "Enable bucket versioning."
  type        = bool
  default     = false
}

# https://cloud.google.com/spanner/docs/pitr
# Must be between 1 hour and 7 days. Can be specified in days, hours, minutes, or seconds.
# eg: 1d, 24h, 1440m, and 86400s are equivalent.
variable "spanner_database_retention_period" {
  description = "Duration to maintain table versioning for point-in-time recovery."
  type        = string
  nullable    = false
  default     = "1h"
}

variable "spanner_instance_config" {
  type        = string
  description = "Multi region config value for the Spanner Instance. Example: 'nam10' for North America."
}

variable "spanner_processing_units" {
  description = "Spanner's compute capacity. 1000 processing units = 1 node and must be set as a multiple of 100."
  type        = number
  default     = 1000
}

variable "spanner_database_deletion_protection" {
  description = "Prevents destruction of the Spanner database."
  type        = bool
  default     = true
}


variable "gke_cluster_ca_certificate" {
  description = "BASE64 encoded CA certificate of deployed GKE cluster"
  type        = string
}

variable "gke_host" {
  description = "Endpoint of deployed GKE cluster"
  type        = string
}

variable "service_account_name" {
  type = string
}