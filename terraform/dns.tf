locals {
  # See https://cloud.google.com/vpc/docs/configure-private-google-access#config-domain
  private_google_access_ips = [
    "199.36.153.8", "199.36.153.9", "199.36.153.10", "199.36.153.11"
  ]
}

module "cloud-dns-private-google-apis" {
  source  = "terraform-google-modules/cloud-dns/google"
  version = "5.0.0"

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
  version = "5.0.0"

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
  version = "5.0.0"

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
