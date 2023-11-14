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

module "pubsub_aggregator" {
  source               = "terraform-google-modules/pubsub/google"
  version              = "6.0.0"
  project_id           = data.google_project.project.id
  topic                = "aggregator-${var.environment}-topic"
  create_subscriptions = true
  create_topic         = true

  pull_subscriptions = [
    {
      name                             = "aggregator-${var.environment}-subscription"
      dead_letter_topic                = "aggregator-${var.environment}-topic-dead-letter"
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

resource "google_pubsub_topic" "modelupdater-topic" {
  name = "modelupdater-${var.environment}-topic"
}

resource "google_pubsub_topic" "modelupdater-dead-letter" {
  name = "modelupdater-${var.environment}-topic-dead-letter"
}

resource "google_pubsub_subscription" "modelupdater-subscription" {
  name  = "modelupdater-${var.environment}-subscription"
  topic = google_pubsub_topic.modelupdater-topic.name

  # 7 days
  message_retention_duration = "604800s"
  retain_acked_messages      = true

  ack_deadline_seconds = 600

  expiration_policy {
    # Dont expire
    ttl = ""
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.modelupdater-dead-letter.id
    max_delivery_attempts = 10
  }

  enable_exactly_once_delivery = true
}

resource "google_pubsub_subscription" "modelupdater-dlq-subscription" {
  name  = "modelupdater-dlq-${var.environment}-subscription"
  topic = google_pubsub_topic.modelupdater-dead-letter.name

  # 7 days
  message_retention_duration = "604800s"
  retain_acked_messages      = true

  ack_deadline_seconds = 600

  expiration_policy {
    # Dont expire
    ttl = ""
  }

  enable_exactly_once_delivery = true
}

resource "google_pubsub_topic_iam_member" "pubsub_sa_publish_modelupdater_deadletter_topic" {
  topic  = google_pubsub_topic.modelupdater-dead-letter.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_subscription_iam_member" "pubsub_sa_pull_modelupdater_topic_sub" {
  subscription = google_pubsub_subscription.modelupdater-subscription.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}
