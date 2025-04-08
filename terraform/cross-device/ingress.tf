resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name = "${var.environment}-ingress"
    annotations = {
      "kubernetes.io/ingress.allow-http"            = "false"
#      "kubernetes.io/ingress.global-static-ip-name" = var.static_ip_name
      "ingress.gcp.kubernetes.io/pre-shared-cert"   = google_compute_managed_ssl_certificate.default.name
    }
    labels = {
      maintained_by = "terraform"
    }
  }

  spec {
    rule {
      host = "taskassignment.${var.parent_domain_name}"
      http {
        path {
          path = "/taskassignment/*"

          backend {
            service {
              name = module.task-assignment.name
              port {
                number = module.task-assignment.port
              }
            }
          }
        }
      }
    }
    rule {
      host = "taskmanagement.${var.parent_domain_name}"
      http {
        path {
          path = "/*"

          backend {
            service {
              name = module.task-management.name
              port {
                number = module.task-management.port
              }
            }
          }
        }
      }
    }
    rule {
      host = "taskbuilder.${var.parent_domain_name}"
      http {
        path {
          path = "/*"

          backend {
            service {
              name = module.task-builder.name
              port {
                number = module.task-builder.port
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    module.task-assignment,
    module.task-management,
    module.task-builder
  ]
}
