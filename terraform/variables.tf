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

variable "project_id" {
  description = "The Google Cloud project ID"
  type        = string
}

variable "region" {
  default     = "europe-west1"
  description = "The region for clusters"
  type        = string
}

variable "zones" {
  default     = ["europe-west1-b"]
  description = "Cluster nodes will be created in each of the following zones. These zones need to be in the region specified by the 'region' variable."
  type        = list(string)
}

variable "cluster_name" {
  default     = "tp-w"
  description = "The GKE cluster name"
  type        = string
}

variable "tenant_names" {
  default     = ["fltenant1"]
  description = "Set of named tenants to be created in the cluster. Each tenant gets a dedicated resources."
  type        = list(string)
}

variable "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation to use for the hosted master network"
  default     = "10.0.0.0/28"
  type        = string
}

variable "cluster_default_pool_machine_type" {
  description = "The machine type for a default node pool"
  default     = "e2-standard-4"
  type        = string
}

variable "cluster_default_pool_min_nodes" {
  description = "The min number of nodes in the default node pool"
  default     = 3
  type        = number
}

variable "cluster_default_pool_max_nodes" {
  description = "The min number of nodes in the default node pool"
  default     = 5
  type        = number
}

variable "cluster_gke_release_channel" {
  default     = "REGULAR"
  description = "Release channel of the GKE cluster"
  type        = string
}

variable "cluster_regional" {
  default     = true
  description = "Set to true to provision a regional GKE cluster"
  type        = bool
}

variable "cluster_tenant_pool_machine_type" {
  description = "The machine type for a tenant node pool"
  default     = "e2-standard-4"
  type        = string
}

variable "cluster_tenant_pool_min_nodes" {
  description = "The min number of nodes in the tenant node pool"
  default     = 2
  type        = number
}

variable "cluster_tenant_pool_max_nodes" {
  description = "The min number of nodes in the tenant node pool"
  default     = 5
  type        = number
}

variable "cluster_secrets_keyname" {
  description = "The name of the Cloud KMS key used to encrypt cluster secrets"
  default     = "clusterSecretsKey"
  type        = string
}

variable "acm_version" {
  description = "Anthos Config Management version"
  default     = "1.9.0"
  type        = string
}

variable "acm_repo_location" {
  default     = "https://github.com/GoogleCloudPlatform/gke-third-party-apps-blueprint"
  description = "The location of the Git repo Anthos Config Management will sync to"
  type        = string
}

variable "acm_branch" {
  default     = "main"
  description = "The Git branch Anthos Config Management will sync to"
  type        = string
}

variable "acm_dir" {
  default     = "configsync"
  description = "The directory in the repository that Anthos Config Management will sync to"
  type        = string
}

variable "acm_secret_type" {
  default     = "none"
  description = "Git authentication secret type. The default value assumes that the repository is publicly accessible."
  type        = string
}

variable "asm_release_channel" {
  description = "Anthos Service Mesh release channel. See https://cloud.google.com/service-mesh/docs/managed/select-a-release-channel for more information"
  default     = "regular"
  type        = string
}

variable "asm_enable_mesh_feature" {
  description = "Set to true to enable Anthos Service Mesh feature. It is required to install the ASM CRDs."
  default     = true
  type        = bool
}

variable "gke_rbac_security_group_domain" {
  default     = null
  description = "Domain of the Google Group to assign RBAC permissions. For more information, refer to https://cloud.google.com/kubernetes-engine/docs/how-to/google-groups-rbac"
  type        = string
}
