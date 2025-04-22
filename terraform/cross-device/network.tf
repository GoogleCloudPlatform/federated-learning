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

resource "google_compute_global_address" "default" {
  name = "cdn-${var.environment}-ip"

}

data "google_dns_managed_zone" "dns_zone" {
  ## (TODO) To be replaced
  #  name = replace(var.parent_domain_name, ".", "-")
  name = "lgrangeau-demo"
}

# Add A record for loadbalancer IPs.
resource "google_dns_record_set" "a" {
  for_each = toset(local.domains)

  name         = "${each.value}."
  managed_zone = data.google_dns_managed_zone.dns_zone.name
  type         = "A"
  ttl          = 300

  rrdatas = [google_compute_global_address.default.address]
}

resource "google_compute_target_https_proxy" "default" {
  name             = "${var.environment}-proxy"
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
}

resource "google_compute_url_map" "default" {
  name        = "${var.environment}-https-lb"
  description = "${var.environment} HTTPS Load Balancer"

  default_service = google_compute_backend_service.default.id

  dynamic "host_rule" {
    for_each = toset(local.domains)
    content {
      hosts        = [host_rule.value]
      path_matcher = "allpaths"
    }
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.default.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.default.id
    }
  }
}

resource "google_compute_backend_service" "default" {
  name        = "${var.environment}-backend-service"
  port_name   = "https"
  protocol    = "HTTPS"
  timeout_sec = 10

  health_checks = [google_compute_https_health_check.default.id]
}

resource "google_compute_https_health_check" "default" {
  name               = "${var.environment}-https-health-check"
  request_path       = "/"
  check_interval_sec = 1
  timeout_sec        = 1
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "${var.environment}-forwarding-rule"
  target     = google_compute_target_https_proxy.default.id
  ip_address = google_compute_global_address.default.id
  port_range = 443
}
