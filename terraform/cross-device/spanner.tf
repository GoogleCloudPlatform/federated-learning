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
  file_contents = file("${path.module}/files/spanner.ddl.sql")
  string_list   = split("\n", local.file_contents)
}

resource "google_spanner_instance" "fcp_task_spanner_instance" {
  name             = "fcp-task-${var.environment}"
  display_name     = "fcp-task-${var.environment}"
  project          = data.google_project.project.project_id
  config           = var.spanner_instance_config
  processing_units = var.spanner_processing_units
}

resource "google_spanner_database" "fcp_task_spanner_database" {
  instance                 = google_spanner_instance.fcp_task_spanner_instance.name
  name                     = "fcp-task-db-${var.environment}"
  project                  = data.google_project.project.project_id
  version_retention_period = var.spanner_database_retention_period
  deletion_protection      = var.spanner_database_deletion_protection
  ddl                      = local.string_list
}

# Spanner configuration for ODP services
# Create Spanner instance
resource "google_spanner_instance" "odp_spanner" {
  name         = "odp-federated-compute"
  config       = "regional-${var.region}"
  display_name = "ODP Federated Compute Database"
  num_nodes    = 1

  labels = {
    environment = var.environment
    purpose     = "odp-federated-compute"
  }
}

# Create Spanner database
resource "google_spanner_database" "odp_db" {
  instance                 = google_spanner_instance.odp_spanner.name
  name                     = "odp-federated-compute"
  version_retention_period = "7d"
  deletion_protection      = true

  ddl = [
    file("${path.module}/spanner/schema/tasks.sdl"),
    file("${path.module}/spanner/schema/clients.sdl"),
    file("${path.module}/spanner/schema/models.sdl"),
    file("${path.module}/spanner/schema/aggregations.sdl")
  ]
}
