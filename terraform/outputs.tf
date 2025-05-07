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

locals {
  container_image_repository_fully_qualified_hostname = "${google_artifact_registry_repository.container_image_repository.location}-docker.pkg.dev"
  container_image_repository_name                     = "${google_artifact_registry_repository.container_image_repository.project}/${google_artifact_registry_repository.container_image_repository.repository_id}"
}

output "container_image_repository_fully_qualified_hostname" {
  description = "Fully qualified name of the container image repository."
  value       = local.container_image_repository_fully_qualified_hostname
}

output "container_image_repository_name" {
  description = "Container image repository name."
  value       = local.container_image_repository_name
}

output "nvflare_workspace_bucket_name" {
  description = "Nvflare bucket name"
  value       = var.nvflare == true ? module.nvflare[0].workspace_bucket_name : null
}

output "acm_repository_path" {
  description = "Path to the Config Management repository on the local machine"
  value       = var.acm_repository_path
}

output "acm_config_sync_configuration_destination_directory_path" {
  description = "Path to the configuration directory in the Config Sync repository"
  value       = local.acm_config_sync_destination_directory_path
}

output "acm_config_sync_tenants_configuration_destination_directory_path" {
  description = "Path to the tenants configuration directory in the Config Sync repository"
  value       = local.acm_config_sync_tenants_configuration_destination_directory_path
}

output "cluster_name" {
  description = "Name of the cluster deployed"
  value       = module.gke.name
}

output "cluster_location" {
  description = "Location of the cluster deployed"
  value       = module.gke.location
}

output "nvflare_namespace" {
  description = "Name of the namespace where the NVFlare example is deployed"
  value       = var.nvflare ? var.nvflare_namespace : null
}

output "aggregator_compute_service_account_email" {
  description = "Service account to be allowlisted for aggregation support"
  value = var.cross_device ? module.cross_device[*].aggregator_compute_service_account_email : null
}

output "model_updater_compute_service_account_email" {
  description = "Service account to be allowlisted for model update support"
  value = var.cross_device ? module.cross_device[*].model_updater_compute_service_account_email : null
}
