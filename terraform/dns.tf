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
  # See https://cloud.google.com/vpc/docs/configure-private-google-access#config-domain
  private_google_access_ips = [
    "199.36.153.8", "199.36.153.9", "199.36.153.10", "199.36.153.11"
  ]
}

module "cloud-dns-private-google-apis" {
  source  = "terraform-google-modules/cloud-dns/google"
  version = "5.3.0"

  description = "Private DNS zone for Google APIs"
  domain      = "googleapis.com."
  name        = "private-google-apis"
  project_id  = data.google_project.project.project_id
  type        = "private"

  private_visibility_config_networks = [
    module.fedlearn-vpc.network_id
  ]

  recordsets = [
    {
      name = "*"
      type = "CNAME"
      ttl  = 300
      records = [
        "private.googleapis.com.",
      ]
    },
    {
      name    = "private"
      type    = "A"
      ttl     = 300
      records = local.private_google_access_ips
    },
  ]
}

module "cloud-dns-private-container-registry" {
  source  = "terraform-google-modules/cloud-dns/google"
  version = "5.3.0"

  description = "Private DNS zone for Container Registry"
  domain      = "gcr.io."
  name        = "private-container-registry"
  project_id  = data.google_project.project.project_id
  type        = "private"

  private_visibility_config_networks = [
    module.fedlearn-vpc.network_id
  ]

  recordsets = [
    {
      name = "*"
      type = "CNAME"
      ttl  = 300
      records = [
        "gcr.io.",
      ]
    },
    {
      name    = ""
      type    = "A"
      ttl     = 300
      records = local.private_google_access_ips
    },
  ]
}

module "cloud-dns-private-artifact-registry" {
  source  = "terraform-google-modules/cloud-dns/google"
  version = "5.3.0"

  description = "Private DNS zone for Artifact Registry"
  domain      = "pkg.dev."
  name        = "private-artifact-registry"
  project_id  = data.google_project.project.project_id
  type        = "private"

  private_visibility_config_networks = [
    module.fedlearn-vpc.network_id
  ]

  recordsets = [
    {
      name = "*"
      type = "CNAME"
      ttl  = 300
      records = [
        "pkg.dev.",
      ]
    },
    {
      name    = ""
      type    = "A"
      ttl     = 300
      records = local.private_google_access_ips
    },
  ]
}

module "distributed-tff-example-dns" {
  count = local.distributed_tff_example_is_there_a_coordinator && local.distributed_tff_example_are_workers_outside_the_coordinator_mesh ? 1 : 0

  source  = "terraform-google-modules/cloud-dns/google"
  version = "5.3.0"

  description = "Private DNS zone for the distributed TensorFlow Federated example"
  domain      = "${local.distributed_tff_example_external_domain}."
  name        = "distributed-tff-example"
  project_id  = data.google_project.project.project_id
  type        = "private"

  private_visibility_config_networks = [
    module.fedlearn-vpc.network_id
  ]

  recordsets = [
    {
      name    = local.distributed_tff_example_worker_1_hostname
      type    = "A"
      ttl     = 300
      records = [var.distributed_tff_example_worker_1_address]
    },
    {
      name    = local.distributed_tff_example_worker_2_hostname
      type    = "A"
      ttl     = 300
      records = [var.distributed_tff_example_worker_2_address]
    },
  ]
}
