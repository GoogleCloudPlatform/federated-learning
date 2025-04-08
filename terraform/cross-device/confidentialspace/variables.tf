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
  description = "GCP Project ID in which this module will be created."
  type        = string
}

variable "environment" {
  description = "Description for the environment, e.g. dev, staging, production"
  type        = string
}

variable "name" {
  description = "Name of Confidential Space workload"
  type        = string
}

variable "region" {
  description = "Region where all services will be created."
  type        = string
}

variable "network_name" {
  description = "The name of the network created."
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet created."
  type        = string
}

variable "workload_image" {
  description = "The workload container image to run."
  type        = string
}

variable "instance_source_image" {
  description = "The OS source container image to run."
  type        = string
}

variable "machine_type" {
  description = "The machine type of the VM."
  type        = string
}

variable "compute_service_account" {
  description = "The service account to use for the compute"
  type        = string
}

variable "jobqueue_subscription_name" {
  description = "Subscription name of the job queue."
  type        = string
}

variable "allowed_operator_service_accounts" {
  description = "The service accounts provided by coordinator for the worker to impersonate."
  type        = string
}

variable "autoscaling_jobs_per_instance" {
  description = "The ratio of jobs to worker instances to scale by."
  type        = number
}

variable "max_replicas" {
  description = "The maximum number of instances that the autoscaler can scale up to. "
  type        = number
}

variable "min_replicas" {
  description = "The minimum number of replicas that the autoscaler can scale down to."
  type        = number
}

variable "cooldown_period" {
  description = "The number of seconds that the autoscaler should wait before it starts collecting information from a new instance."
  type        = number
}
