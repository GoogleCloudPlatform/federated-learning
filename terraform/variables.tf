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
  default     = []
  description = "Cluster nodes will be created in each of the following zones. These zones need to be in the region specified by the 'region' variable."
  type        = list(string)
}

variable "google_artifact_registry_location" {
  default     = "europe"
  description = "The default location where to create Artifact Registry repositories."
  type        = string
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
  default     = 1
  type        = number
}

variable "cluster_default_pool_max_nodes" {
  description = "The max number of nodes in the default node pool"
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
  default     = 1
  type        = number
}

variable "cluster_tenant_pool_max_nodes" {
  description = "The max number of nodes in the tenant node pool"
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
  default     = ""
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

# We can't validate if this directory exists because the fileexists function
# doesn't support directories (yet?)
# Ref: https://github.com/hashicorp/terraform/issues/33394
variable "acm_repository_path" {
  description = "Path to the Config Management repository on the local machine"
  type        = string
}

variable "gke_rbac_security_group_domain" {
  default     = null
  description = "Domain of the Google Group to assign RBAC permissions. For more information, refer to https://cloud.google.com/kubernetes-engine/docs/how-to/google-groups-rbac"
  type        = string
}

variable "distributed_tff_example_worker_1_address" {
  default     = ""
  description = "Address of the first worker of the distributed TensorFlow Federated example."
  type        = string
}

variable "distributed_tff_example_worker_2_address" {
  default     = ""
  description = "Address of the second worker of the distributed TensorFlow Federated example."
  type        = string
}

variable "distributed_tff_example_deploy" {
  default     = false
  description = "Set to true to deploy a TensorFlow Federated example in the cluster."
  type        = bool
}

variable "distributed_tff_example_deploy_ingress_gateway" {
  default     = false
  description = "Set to true to deploy an Ingress Gateway to expose workers."
  type        = bool
}

variable "distributed_tff_example_is_coordinator" {
  default     = false
  description = "Set to true to deploy a coordinator for the TensorFlow Federated example in the cluster."
  type        = bool
}

variable "distributed_tff_example_deploy_namespace" {
  default     = "fltenant1"
  description = "Name of the Kubernetes namespace where to deploy the distributed TensorFlow Federated example."
  type        = string
}

variable "distributed_tff_example_worker_emnist_partition_file_name" {
  default     = ""
  description = "Name of the EMNIST partition file of the distributed TensorFlow Federated example."
  type        = string
}
