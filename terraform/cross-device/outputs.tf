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

output "odp_service_endpoints" {
  description = "Internal service endpoints for ODP services"
  value = {
    for k, v in kubernetes_service.odp_services : k => "${k}.${local.odp_namespace}.svc.cluster.local"
  }
}

# Add Spanner-related outputs
output "spanner_instance" {
  description = "The name of the Spanner instance"
  value       = google_spanner_instance.odp_spanner.name
}

output "spanner_database" {
  description = "The name of the Spanner database"
  value       = google_spanner_database.odp_db.name
}

output "spanner_instance_config" {
  description = "The configuration for the Spanner instance"
  value       = google_spanner_instance.odp_spanner.config
}
