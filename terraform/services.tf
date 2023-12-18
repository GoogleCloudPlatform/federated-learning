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

module "project-services-cloud-resource-manager" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "14.4.0"

  project_id                  = var.project_id
  disable_services_on_destroy = false
  activate_apis = [
    "cloudresourcemanager.googleapis.com"
  ]
}


module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "14.4.0"

  project_id                  = var.project_id
  disable_services_on_destroy = false
  activate_apis = [
    "anthos.googleapis.com",
    "anthosconfigmanagement.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudtrace.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "dns.googleapis.com",
    "gkeconnect.googleapis.com",
    "gkehub.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "mesh.googleapis.com",
    "meshca.googleapis.com",
    "meshconfig.googleapis.com",
    "meshtelemetry.googleapis.com",
    "monitoring.googleapis.com",
    "run.googleapis.com",
    "sourcerepo.googleapis.com",
    "spanner.googleapis.com",
    "stackdriver.googleapis.com"
  ]

  depends_on = [
    module.project-services-cloud-resource-manager
  ]
}
