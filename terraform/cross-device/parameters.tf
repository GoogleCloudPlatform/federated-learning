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
  parameters = {
    "ENCRYPTION_KEY_SERVICE_A_BASE_URL"          = var.encryption_key_service_a_base_url
    "ENCRYPTION_KEY_SERVICE_B_BASE_URL"          = var.encryption_key_service_b_base_url
    "ENCRYPTION_KEY_SERVICE_A_CLOUDFUNCTION_URL" = var.encryption_key_service_a_cloudfunction_url
    "ENCRYPTION_KEY_SERVICE_B_CLOUDFUNCTION_URL" = var.encryption_key_service_b_cloudfunction_url
    "WIP_PROVIDER_A"                             = var.wip_provider_a
    "WIP_PROVIDER_B"                             = var.wip_provider_b
    "SERVICE_ACCOUNT_A"                          = var.service_account_a
    "SERVICE_ACCOUNT_B"                          = var.service_account_b
    "MODEL_UPDATER_PUBSUB_SUBSCRIPTION"          = module.pubsub["modelupdater_topic"].subscription_names[0]
    "MODEL_UPDATER_PUBSUB_TOPIC"                 = module.pubsub["modelupdater_topic"].topic
    "AGGREGATOR_PUBSUB_SUBSCRIPTION"             = module.pubsub["aggregator_topic"].subscription_names[0]
    "AGGREGATOR_PUBSUB_TOPIC"                    = module.pubsub["aggregator_topic"].topic
    "AGGREGATOR_NOTIF_PUBSUB_SUBSCRIPTION"       = module.pubsub["aggregator_notifications_topic"].subscription_names[0]
    "AGGREGATOR_NOTIF_PUBSUB_TOPIC"              = module.pubsub["aggregator_notifications_topic"].topic
    "SPANNER_INSTANCE"                           = google_spanner_instance.odp_spanner.name
    "TASK_DATABASE_NAME"                         = google_spanner_database.odp_db.name
    "LOCK_DATABASE_NAME"                         = google_spanner_database.odp_db.name
    "METRICS_SPANNER_INSTANCE"                   = google_spanner_instance.odp_spanner.name
    "METRICS_DATABASE_NAME"                      = google_spanner_database.odp_db.name
    "CLIENT_GRADIENT_BUCKET_TEMPLATE"            = module.buckets.names["model-0"]
    "AGGREGATED_GRADIENT_BUCKET_TEMPLATE"        = module.buckets.names["aggregated-gradient-0"]
    "MODEL_BUCKET_TEMPLATE"                      = module.buckets.names["client-gradient-0"]
    "DOWNLOAD_PLAN_TOKEN_DURATION"               = var.download_plan_token_duration
    "DOWNLOAD_CHECKPOINT_TOKEN_DURATION"         = var.download_checkpoint_token_duration
    "UPLOAD_GRADIENT_TOKEN_DURATION"             = var.upload_gradient_token_duration
    "IS_AUTHENTICATION_ENABLED"                  = var.is_authentication_enabled
    "ALLOW_ROOTED_DEVICES"                       = var.allow_rooted_devices
    "LOCAL_COMPUTE_TIMEOUT_MINUTES"              = var.local_compute_timeout_minutes
    "UPLOAD_TIMEOUT_MINUTES"                     = var.upload_timeout_minutes
    "COLLECTOR_BATCH_SIZE"                       = var.collector_batch_size
    "AGGREGATION_BATCH_FAILURE_THRESHOLD"        = var.aggregation_batch_failure_threshold
  }
}

module "encryption_key_service_a_base_url" {
  for_each        = local.parameters
  source          = "./secretmanager"
  environment     = var.environment
  parameter_name  = each.key
  parameter_value = each.value
}
