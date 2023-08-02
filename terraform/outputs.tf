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

output "artifact_registry_container_image_repository_location" {
  description = "Location of the Artifact Registry repository to store container images."
  value       = google_artifact_registry_repository.container_image_repository.location
}

output "artifact_registry_container_image_repository_name" {
  description = "Last part of the name of the Artifact Registry container image repository."
  value       = google_artifact_registry_repository.container_image_repository.repository_id
}

output "artifact_registry_container_image_repository_project_id" {
  description = "ID of the Artifact Registry container image repository Google Cloud project."
  value       = google_artifact_registry_repository.container_image_repository.project
}

output "config_sync_repository_path" {
  description = "Path to the Config Sync repository on the local machine."
  value       = var.acm_repository_path
}

output "kubernetes_apps_service_account_name" {
  description = "Kubernetes service account name for workloads running in the cluster"
  value       = module.fl-workload-identity.k8s_sa_name
}
