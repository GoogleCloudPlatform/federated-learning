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

data "google_compute_zones" "available" {
}

resource "google_compute_instance_template" "instance_template" {
  project = var.project_id
  region  = var.region
  
  disk {
    auto_delete  = true
    boot         = true
    device_name  = "${var.environment}-${var.name}"
    source_image = var.instance_source_image
    disk_type    = "pd-balanced"
    mode         = "READ_WRITE"
  }

  machine_type     = var.machine_type
  min_cpu_platform = "AMD Milan"

  metadata = {
    # Allocate 2GB to dev/shm
    tee-dev-shm-size-kb              = 2000000
    tee-image-reference              = var.workload_image
    tee-container-log-redirect       = true
    tee-impersonate-service-accounts = var.allowed_operator_service_accounts
    tee-monitoring-memory-enable     = true
    environment                      = var.environment
  }

  name_prefix = "${var.environment}-${var.name}-"

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    network            = var.network_name
    subnetwork         = var.subnet_name
    subnetwork_project = var.project_id
  }

  scheduling {
    # Confidential compute can be set to "MIGRATE" only when
    # confidential_instance_type = "SEV" and min_cpu_platform = "AMD Milan"
    on_host_maintenance = "MIGRATE"
  }

  confidential_instance_config {
    confidential_instance_type = "SEV"
  }

  service_account {
    email  = var.compute_service_account
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_firewall" "firewall" {
  name    = "${var.environment}-${var.name}-firewall"
  network = var.network_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["8082"]
  }
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
}

resource "google_compute_firewall" "ssh" {
  name    = "${var.environment}-${var.name}-ssh"
  network = var.network_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_region_instance_group_manager" "instance_group" {
  name               = "${var.environment}-${var.name}-instance-group"
  description        = "${var.name} instance group"
  project            = var.project_id
  base_instance_name = "${var.environment}-${var.name}"

  version {
    instance_template = google_compute_instance_template.instance_template.id
    name              = "${var.environment}-${var.name}"
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.default.id
    initial_delay_sec = var.cooldown_period
  }

  update_policy {
    max_surge_fixed = length(data.google_compute_zones.available.names)
    minimal_action  = "REPLACE"
    type            = "PROACTIVE"
  }

  region = var.region
}

resource "google_compute_health_check" "default" {
  name                = "${var.environment}-${var.name}-http-health-check"
  timeout_sec         = 10
  check_interval_sec  = 30
  healthy_threshold   = 1
  unhealthy_threshold = 3
  http_health_check {
    request_path = "/healthz"
    port         = "8082"
  }
}

resource "google_compute_region_autoscaler" "autoscaler" {
  provider = google-beta

  name    = "${var.environment}-${var.name}-autoscaler"
  project = var.project_id
  region  = var.region
  target  = google_compute_region_instance_group_manager.instance_group.id

  autoscaling_policy {
    max_replicas = var.max_replicas
    min_replicas = var.min_replicas
    # The number of seconds that the autoscaler should wait before it starts collecting information from a new instance.
    cooldown_period = var.cooldown_period

    metric {
      name                       = "pubsub.googleapis.com/subscription/num_undelivered_messages"
      filter                     = "resource.type = pubsub_subscription AND resource.label.subscription_id = ${var.jobqueue_subscription_name}"
      single_instance_assignment = var.autoscaling_jobs_per_instance
    }
  }

  # Required otherwise worker_instance_group hits resourceInUseByAnotherResource error when replacing
  lifecycle {
    replace_triggered_by = [google_compute_region_instance_group_manager.instance_group.id]
  }
}
