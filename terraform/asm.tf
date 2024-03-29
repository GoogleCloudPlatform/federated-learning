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

resource "google_gke_hub_feature" "mesh_feature" {
  name     = "servicemesh"
  project  = data.google_project.project.project_id
  location = "global"
  provider = google-beta
}

# This is needed until https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/pull/1702
# is merged, and we update to a ASM module release that includes that.
resource "google_gke_hub_feature_membership" "mesh_feature_membership" {
  location   = google_gke_hub_feature.mesh_feature.location
  feature    = google_gke_hub_feature.mesh_feature.name
  membership = module.gke.name
  mesh {
    management = "MANAGEMENT_AUTOMATIC"
  }
  provider = google-beta
}

# Wait for the ControlPlaneRevision custom resource to be ready.
# Add an explicit "retry until the resource is created" until
# https://github.com/kubernetes/kubernetes/issues/83242 is implemented.
module "kubectl_asm_wait_for_controlplanerevision_custom_resource_definition" {
  source  = "terraform-google-modules/gcloud/google//modules/kubectl-wrapper"
  version = "3.1.2"

  project_id              = data.google_project.project.project_id
  cluster_name            = module.gke.name
  cluster_location        = module.gke.location
  kubectl_create_command  = "/bin/sh -c 'while ! kubectl wait crd/controlplanerevisions.mesh.cloud.google.com --for condition=established --timeout=60m --all-namespaces; do echo \"crd/controlplanerevisions.mesh.cloud.google.com not yet available, waiting...\"; sleep 5; done'"
  kubectl_destroy_command = ""

  module_depends_on = [
    google_gke_hub_feature_membership.mesh_feature_membership
  ]
}

# Wait for the ASM control plane revision to be ready so we can safely deploy resources that depend
# on ASM mutating webhooks.
# Add an explicit "retry until the resource is created" until
# https://github.com/kubernetes/kubernetes/issues/83242 is implemented.
module "kubectl_asm_wait_for_controlplanerevision" {
  source  = "terraform-google-modules/gcloud/google//modules/kubectl-wrapper"
  version = "3.1.2"

  project_id              = data.google_project.project.project_id
  cluster_name            = module.gke.name
  cluster_location        = module.gke.location
  kubectl_create_command  = "/bin/sh -c 'while ! kubectl -n istio-system wait ControlPlaneRevision --all --timeout=60m --for condition=Reconciled; do echo \"ControlPlaneRevision not yet available, waiting...\"; sleep 5; done'"
  kubectl_destroy_command = ""

  module_depends_on = [
    module.kubectl_asm_wait_for_controlplanerevision_custom_resource_definition.wait
  ]
}
