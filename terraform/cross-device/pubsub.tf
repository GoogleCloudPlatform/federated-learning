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

module "pubsub_aggregator_dl" {
  source               = "terraform-google-modules/pubsub/google"
  version              = "6.0.0"
  project_id           = data.google_project.project.project_id
  topic                = "aggregator-${var.environment}-topic-dead-letter"
  create_subscriptions = true
  create_topic         = true

  pull_subscriptions = [
    {
      name                             = "aggregator-dlq-${var.environment}-subscription"
      topic_message_retention_duration = "604800s"
      retain_acked_messages            = true
      ack_deadline_seconds             = 600
      enable_exactly_once_delivery     = true
      service_account                  = "service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
      expiration_policy                = ""
    }
  ]
}

module "pubsub_aggregator" {
  source               = "terraform-google-modules/pubsub/google"
  version              = "6.0.0"
  project_id           = data.google_project.project.project_id
  topic                = "aggregator-${var.environment}-topic"
  create_subscriptions = true
  create_topic         = true

  pull_subscriptions = [
    {
      name                             = "aggregator-${var.environment}-subscription"
      dead_letter_topic                = "projects/${var.project_id}/topics/aggregator-${var.environment}-topic-dead-letter"
      topic_message_retention_duration = "604800s"
      retain_acked_messages            = true
      ack_deadline_seconds             = 600
      max_delivery_attempts            = 10
      enable_exactly_once_delivery     = true
      service_account                  = "service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
      expiration_policy                = ""
    }
  ]
}

module "pubsub_modelupdater_dl" {
  source               = "terraform-google-modules/pubsub/google"
  version              = "6.0.0"
  project_id           = data.google_project.project.project_id
  topic                = "modelupdater-${var.environment}-topic-dead-letter"
  create_subscriptions = true
  create_topic         = true

  pull_subscriptions = [
    {
      name                             = "modelupdater-dlq-${var.environment}-subscription"
      topic_message_retention_duration = "604800s"
      retain_acked_messages            = true
      ack_deadline_seconds             = 600
      enable_exactly_once_delivery     = true
      service_account                  = "service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
      expiration_policy                = ""
    }
  ]
}

module "pubsub_modelupdater" {
  source               = "terraform-google-modules/pubsub/google"
  version              = "6.0.0"
  project_id           = data.google_project.project.project_id
  topic                = "modelupdater-${var.environment}-topic"
  create_subscriptions = true
  create_topic         = true

  pull_subscriptions = [
    {
      name                             = "modelupdater-${var.environment}-subscription"
      dead_letter_topic                = "projects/${var.project_id}/topics/modelupdater-${var.environment}-topic-dead-letter"
      topic_message_retention_duration = "604800s"
      retain_acked_messages            = true
      ack_deadline_seconds             = 600
      max_delivery_attempts            = 10
      enable_exactly_once_delivery     = true
      service_account                  = "service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
      expiration_policy                = ""
    }
  ]
}
