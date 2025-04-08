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

# Create Kubernetes deployments for ODP services
resource "kubernetes_deployment" "odp_services" {
  metadata {
    name      = "${var.environment}-${var.name}"
    namespace = var.namespace

    labels = {
      app     = "odp-federated"
      service = var.name
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app     = "odp-federated"
        service = var.name
      }
    }

    template {
      metadata {
        labels = {
          app     = "odp-federated"
          service = var.name
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/path"   = "/actuator/prometheus"
          "prometheus.io/port"   = "8080"
        }
      }

      spec {
        service_account_name = var.service_account_name

        container {
          name  = var.name
          image = "${var.image}:latest"

          dynamic "port" {
            for_each = var.ports
            content {
              container_port = port.value.containerPort
              name           = port.value.name
              protocol       = port.value.protocol
            }
          }

          env {
            name  = "JAVA_TOOL_OPTIONS"
            value = var.java_opts
          }

          dynamic "env" {
            for_each = var.env
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
            for_each = var.ports
            content {
              http_get {
                path = "/healthz"
                port = liveness_probe.value.containerPort
              }
            }
          }

          dynamic "readiness_probe" {
            for_each = var.ports
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
  metadata {
    name      = "${var.environment}-${var.name}"
    namespace = var.namespace

    labels = {
      app     = "odp-federated"
      service = var.name
    }
  }

  spec {
    selector = {
      app     = "odp-federated"
      service = var.name
    }

    dynamic "port" {
      for_each = var.ports
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
  metadata {
    name      = "${var.environment}-${var.name}"
    namespace = var.namespace
  }

  spec {
    min_replicas = var.hpa.min_replicas
    max_replicas = var.hpa.max_replicas

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
      name        = var.name
    }
  }
}

