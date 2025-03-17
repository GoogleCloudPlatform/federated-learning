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

variable "enable_confidential_nodes" {
  description = "Enable Confidential Nodes to ensure end-to-end confidentiality. It is also necessary to use VM families that support this feature, such as **N2D** or **C2D**"
  default     = false
  type        = bool
}

variable "acm_version" {
  description = "Config Management version"
  default     = ""
  type        = string
}

variable "acm_branch" {
  default     = "main"
  description = "Name of the Git branch in the repository that Config Sync will sync with"
  type        = string
}

variable "acm_dir" {
  default     = "configsync"
  description = "The directory in the repository that Config Sync will sync with"
  type        = string
}

variable "acm_repository_url" {
  description = "The URL of the repository that Config Sync will sync with"
  type        = string
}

variable "acm_secret_type" {
  description = "Secret type to authenticate with the Config Sync Git repository. Ref: https://cloud.google.com/kubernetes-engine/enterprise/config-sync/docs/how-to/installing-config-sync#git-creds-secret"
  type        = string
}

variable "acm_source_repository_fqdns" {
  description = "FQDNs of source repository for Config Sync to allow in the Network Firewall Policy"
  type        = list(string)
}

variable "acm_repository_path" {
  description = "Path to the Config Management repository on the local machine"
  type        = string
}

variable "gke_rbac_security_group_domain" {
  default     = null
  description = "Domain of the Google Group to assign RBAC permissions. For more information, refer to https://cloud.google.com/kubernetes-engine/docs/how-to/google-groups-rbac"
  type        = string
}

variable "cross_device" {
  description = "Enable cross device infrastructure deployment"
  type        = bool
  default     = false
}

variable "nvflare" {
  description = "Enable nvflare infrastructure deployment"
  type        = bool
  default     = false
}

variable "spanner_instance_config" {
  description = "Multi region config value for the Spanner Instance. Example: 'nam10' for North America."
  type        = string
  default     = "regional-europe-west1"
}

variable "spanner_processing_units" {
  description = "Spanner's compute capacity. 1000 processing units = 1 node and must be set as a multiple of 100."
  type        = number
  default     = 1000
}

variable "cross_device_workloads_kubernetes_namespace" {
  description = "Namespace of SA where the cross-device workload will be deployed"
  type        = string
  default     = "main"
}

variable "nvflare_namespace" {
  description = "Namespace of SA where the cross-device workload will be deployed"
  type        = string
  default     = "fltenant1"
}

variable "workspace_bucket_name" {
  description = "Bucket name that will contain nvflare workspace"
  default     = ""
  type        = string
}

# Distributed TensorFlow Federated example variables

variable "distributed_tff_example" {
  description = "Set this to true to provision cloud resources for the distributed TensorFlow Federated example"
  default     = false
  type        = bool
}

variable "distributed_tff_example_worker_1_address" {
  description = "IP address of the first worker in the distributed TensorFlow Federated example"
  default     = ""
  type        = string
}

variable "distributed_tff_example_worker_2_address" {
  description = "IP address of the second worker in the distributed TensorFlow Federated example"
  default     = ""
  type        = string
}

variable "encryption_key_service_a_base_url" {
  default     = ""
  type        = string

}

variable "encryption_key_service_b_base_url" {
  default     = ""
  type        = string

}

variable "encryption_key_service_a_cloudfunction_url" {
  default     = ""
  type        = string

}

variable "encryption_key_service_b_cloudfunction_url" {
  default     = ""
  type        = string

}

variable "wip_provider_a" {
  default     = ""
  type        = string

}

variable "wip_provider_b" {
  default     = ""
  type        = string

}

variable "service_account_a" {
  default     = ""
  type        = string

}

variable "service_account_b" {
  default     = ""
  type        = string

}

variable "aggregator_image" {
  default     = ""

}

variable "collector_image" {
  default     = ""

}

variable "model_updater_image" {
  default     = ""

}

variable "task_management_image" {
  default     = ""

}

variable "task_assignment_image" {
  default     = ""

}

variable "task_scheduler_image" {
  default     = ""

}
