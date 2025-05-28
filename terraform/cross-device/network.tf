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
  domains = [
    "taskassignment.${var.parent_domain_name}",
    "taskmanagement.${var.parent_domain_name}",
    "taskbuilder.${var.parent_domain_name}"
  ]
}

resource "google_compute_address" "default" {
  name = "cdn-${var.environment}-ip"
  region = var.region
}

data "google_dns_managed_zone" "dns_zone" {
  name = replace(var.parent_domain_name, ".", "-")
}

# Add A record for loadbalancer IPs.
resource "google_dns_record_set" "a" {
  for_each = toset(local.domains)

  name         = "${each.value}."
  managed_zone = data.google_dns_managed_zone.dns_zone.name
  type         = "A"
  ttl          = 300

  rrdatas = [google_compute_address.default.address]
}
