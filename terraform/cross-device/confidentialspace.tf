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

module "aggregator" {
  source                            = "./confidentialspace"
  allowed_operator_service_accounts = var.allowed_operator_service_accounts
  autoscaling_jobs_per_instance     = var.aggregator_autoscaling_jobs_per_instance
  compute_service_account           = "odp-federated-aggregator-sa@federated-learning-452214.iam.gserviceaccount.com"
  cooldown_period                   = var.aggregator_cooldown_period
  environment                       = var.environment
  instance_source_image             = var.aggregator_instance_source_image
  jobqueue_subscription_name        = "${local.topics.aggregator_topic}-subscription"
  machine_type                      = var.aggregator_machine_type
  max_replicas                      = var.aggregator_max_replicas
  min_replicas                      = var.aggregator_min_replicas
  name                              = "ag"
  network_name                      = var.network_name
  project_id                        = var.project_id
  region                            = var.region
  subnet_name                       = var.subnet_name
  workload_image                    = var.aggregator_image
}

module "model_updater" {
  source                            = "./confidentialspace"
  allowed_operator_service_accounts = var.allowed_operator_service_accounts
  autoscaling_jobs_per_instance     = var.model_updater_autoscaling_jobs_per_instance
  compute_service_account           = "odp-federated-model-updater-sa@federated-learning-452214.iam.gserviceaccount.com"
  cooldown_period                   = var.model_updater_cooldown_period
  environment                       = var.environment
  instance_source_image             = var.model_updater_instance_source_image
  jobqueue_subscription_name        = "${local.topics.modelupdater_topic}-subscription"
  machine_type                      = var.model_updater_machine_type
  max_replicas                      = var.model_updater_max_replicas
  min_replicas                      = var.model_updater_min_replicas
  name                              = "mu"
  network_name                      = var.network_name
  project_id                        = var.project_id
  region                            = var.region
  subnet_name                       = var.subnet_name
  workload_image                    = var.model_updater_image
}
