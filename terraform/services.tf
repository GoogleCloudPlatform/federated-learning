module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "13.0.0"

  project_id                  = var.project_id
  disable_services_on_destroy = false
  activate_apis = [
    "anthos.googleapis.com",
    "anthosconfigmanagement.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudtrace.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "dns.googleapis.com",
    "gkeconnect.googleapis.com",
    "gkehub.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "meshca.googleapis.com",
    "meshconfig.googleapis.com",
    "meshtelemetry.googleapis.com",
    "monitoring.googleapis.com",
    "stackdriver.googleapis.com"
  ]
}
