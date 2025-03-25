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
      ports = [{
        containerPort = 8080
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
      replicas = 1
      ports = [{
        containerPort = 8080
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
      replicas = 1
      ports = [{
        containerPort = 8080
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
      replicas = 1
      ports = [{
        containerPort = 8080
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
  }
}

# Create namespace for ODP services
# resource "kubernetes_namespace" "odp_services" {
#   metadata {
#     name = local.odp_namespace
#     labels = {
#       istio-injection = "enabled"
#       environment     = var.environment
#       purpose         = "odp-federated-compute"
#     }
#   }
# }

# Create Kubernetes deployments for ODP services
resource "kubernetes_deployment" "odp_services" {
  for_each = local.odp_services

  metadata {
    name      = each.key
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

          liveness_probe {
            http_get {
              path = "/actuator/health/liveness"
              port = 8080
            }
            initial_delay_seconds = 90
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/actuator/health/readiness"
              port = 8080
            }
            initial_delay_seconds = 60
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          security_context {
            run_as_non_root = true
            run_as_user     = 10000
            run_as_group    = 10000
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
    name      = each.key
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

# Create network policies
# resource "kubernetes_network_policy" "odp_services" {
#   metadata {
#     name      = "odp-services-network-policy"
#     namespace = kubernetes_namespace.odp_services.metadata[0].name
#   }

#   spec {
#     pod_selector {
#       match_labels = {
#         app = "odp-federated"
#       }
#     }

#     ingress {
#       from {
#         pod_selector {
#           match_labels = {
#             app = "odp-federated"
#           }
#         }
#       }
#       ports {
#         port     = "8080"
#         protocol = "TCP"
#       }
#     }

#     egress {
#       to {
#         pod_selector {}
#       }
#     }

#     policy_types = ["Ingress", "Egress"]
#   }
# }

# Create service mesh configuration
# resource "kubernetes_manifest" "odp_authorization_policy" {
#   manifest = {
#     apiVersion = "security.istio.io/v1beta1"
#     kind       = "AuthorizationPolicy"
#     metadata = {
#       name      = "odp-services-policy"
#       namespace = kubernetes_namespace.odp_services.metadata[0].name
#     }
#     spec = {
#       action = "ALLOW"
#       selector = {
#         matchLabels = {
#           app = "odp-federated"
#         }
#       }
#       rules = [
#         {
#           from = [
#             {
#               source = {
#                 namespaces = [kubernetes_namespace.odp_services.metadata[0].name]
#               }
#             }
#           ]
#         }
#       ]
#     }
#   }
# }
