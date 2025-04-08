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

# ODP Services Configuration
locals {
  odp_namespace = "fltenant1"
  odp_services = {
    collector = {
      replicas = 1
      hpa = {
        min_replicas = 1
        max_replicas = 3
      }
      ports = [{
        containerPort = 8082
        name          = "http"
        protocol      = "TCP"
      }]
      env = {
        FCP_OPTS = "--environment '${var.environment}'"
      }
      java_opts            = "-XX:+UseG1GC -XX:MaxGCPauseMillis=100 -Xmx2g -Xms2g"
      service_account_name = var.collector_sa
      image                = var.collector_image
    }
    "task-assignment" = {
      replicas = 4
      hpa = {
        min_replicas = 4
        max_replicas = 20
      }
      ports = [{
        containerPort = 8083
        name          = "http"
        protocol      = "TCP"
      }]
      env = {
        FCP_OPTS = "--environment '${var.environment}'"
      }
      java_opts            = "-XX:+UseG1GC -XX:MaxGCPauseMillis=100 -Xmx2g -Xms2g"
      service_account_name = var.task_assignment_sa
      image                = var.task_assignment_image
    }
    "task-management" = {
      replicas = 2
      hpa = {
        min_replicas = 2
        max_replicas = 5
      }
      ports = [{
        containerPort = 8082
        name          = "http"
        protocol      = "TCP"
      }]
      env = {
        FCP_OPTS = "--environment '${var.environment}'"
      }
      java_opts            = "-XX:+UseG1GC -XX:MaxGCPauseMillis=100 -Xmx2g -Xms2g"
      service_account_name = var.task_management_sa
      image                = var.task_management_image
    }
    "task-scheduler" = {
      replicas = 2
      hpa = {
        min_replicas = 2
        max_replicas = 5
      }
      ports = [{
        containerPort = 8082
        name          = "http"
        protocol      = "TCP"
      }]
      env = {
        FCP_OPTS = "--environment '${var.environment}'"
      }
      java_opts            = "-XX:+UseG1GC -XX:MaxGCPauseMillis=100 -Xmx2g -Xms2g"
      service_account_name = var.task_scheduler_sa
      image                = var.task_scheduler_image
    }
    "task-builder" = {
      replicas = 2
      hpa = {
        min_replicas = 2
        max_replicas = 5
      }
      ports = [{
        containerPort = 5000
        name          = "http"
        protocol      = "TCP"
      }]
      env = {
        FCP_OPTS                   = "--environment '${var.environment}'"
        TASK_MANAGEMENT_SERVER_URL = kubernetes_service.odp_services["task-management"].spec[0].cluster_ip
        PYTHONUNBUFFERED           = 1
      }
      java_opts            = "-XX:+UseG1GC -XX:MaxGCPauseMillis=100 -Xmx2g -Xms2g"
      service_account_name = var.task_builder_sa
      image                = var.task_builder_image
    }
  }
}

# Create Kubernetes deployments for ODP services
resource "kubernetes_deployment" "odp_services" {
  for_each = local.odp_services

  metadata {
    name      = "${var.environment}-${each.key}"
    namespace = local.odp_namespace

    labels = {
      app     = "odp-federated"
      service = each.key
    }
  }

  spec {
    replicas = each.value.replicas

    selector {
      match_labels = {
        app     = "odp-federated"
        service = each.key
      }
    }

    template {
      metadata {
        labels = {
          app     = "odp-federated"
          service = each.key
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/path"   = "/actuator/prometheus"
          "prometheus.io/port"   = "8080"
        }
      }

      spec {
        service_account_name = each.value.service_account_name

        container {
          name  = each.key
          image = "${each.value.image}:latest"

          dynamic "port" {
            for_each = each.value.ports
            content {
              container_port = port.value.containerPort
              name           = port.value.name
              protocol       = port.value.protocol
            }
          }

          env {
            name  = "JAVA_TOOL_OPTIONS"
            value = each.value.java_opts
          }

          dynamic "env" {
            for_each = each.value.env
            content {
              name  = env.key
              value = env.value
            }
          }

          resources {
            limits = {
              cpu    = "2"
              memory = "3Gi"
            }
            requests = {
              cpu    = "500m"
              memory = "2Gi"
            }
          }

          dynamic "liveness_probe" {
            for_each = each.value.ports
            content {
              http_get {
                path = "/healthz"
                port = liveness_probe.value.containerPort
              }
            }
          }

          dynamic "readiness_probe" {
            for_each = each.value.ports
            content {
              http_get {
                path = "/ready"
                port = readiness_probe.value.containerPort
              }
            }
          }

          security_context {
            run_as_non_root            = true
            allow_privilege_escalation = false
            privileged                 = false
            run_as_user                = 10000
            run_as_group               = 10000

            capabilities {
              add  = []
              drop = ["NET_RAW"]
            }
          }
        }
      }
    }
  }
}

# Create Kubernetes services for ODP services
resource "kubernetes_service" "odp_services" {
  for_each = local.odp_services

  metadata {
    name      = "${var.environment}-${each.key}"
    namespace = local.odp_namespace

    labels = {
      app     = "odp-federated"
      service = each.key
    }
  }

  spec {
    selector = {
      app     = "odp-federated"
      service = each.key
    }

    dynamic "port" {
      for_each = each.value.ports
      content {
        port        = port.value.containerPort
        target_port = port.value.containerPort
        name        = port.value.name
        protocol    = port.value.protocol
      }
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "odp_services" {
  for_each = local.odp_services

  metadata {
    name      = "${var.environment}-${each.key}"
    namespace = local.odp_namespace
  }

  spec {
    min_replicas = each.value.hpa.min_replicas
    max_replicas = each.value.hpa.max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = "70"
        }
      }
    }

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.odp_services[each.key].metadata[0].name
    }
  }
}

resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name = "${var.environment}-ingress"
    annotations = {
      "kubernetes.io/ingress.allow-http"            = "false"
      "kubernetes.io/ingress.global-static-ip-name" = var.static_ip_name
      "ingress.gcp.kubernetes.io/pre-shared-cert"   = google_compute_managed_ssl_certificate.default.name
    }
    labels = {
      maintained_by = "terraform"
    }
  }

  spec {
    rule {
      http {
        path {
          backend {
            service {
              name = kubernetes_service_v1.taskassignment.metadata[0].name
              port {
                number = var.task_assignment_port
              }
            }
          }

          path = "/taskassignment/*"
        }
      }
    }
  }
}

resource "google_compute_managed_ssl_certificate" "default" {
  name     = "${var.environment}-cert"
  provider = google
  managed {
    domains = [var.parent_domain_name]
  }
}
