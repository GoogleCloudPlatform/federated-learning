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
  file_contents = file("${path.module}/my_file.txt")
  string_list   = split(local.file_contents, "\n")
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
