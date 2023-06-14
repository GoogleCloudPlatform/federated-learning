locals {
  # See https://cloud.google.com/vpc/docs/configure-private-google-access#config-domain
  private_google_access_ips = [
    "199.36.153.8", "199.36.153.9", "199.36.153.10", "199.36.153.11"
  ]
}

resource "google_dns_managed_zone" "private-google-apis" {
  name        = "private-google-apis"
  dns_name    = "googleapis.com."
  description = "Private DNS zone for Google APIs"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = module.fedlearn-vpc.network_id
    }
  }
}

resource "google_dns_record_set" "private-google-apis-cname" {
  managed_zone = google_dns_managed_zone.private-google-apis.name
  name         = "*.googleapis.com."
  type         = "CNAME"
  rrdatas      = ["private.googleapis.com."]
  ttl          = 300
}

resource "google_dns_record_set" "private-google-apis-a" {
  managed_zone = google_dns_managed_zone.private-google-apis.name
  name         = "private.googleapis.com."
  type         = "A"
  rrdatas      = local.private_google_access_ips
  ttl          = 300
}



resource "google_dns_managed_zone" "private-container-registry" {
  name        = "private-container-registry"
  dns_name    = "gcr.io."
  description = "Private DNS zone for Container Registry"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = module.fedlearn-vpc.network_id
    }
  }
}

resource "google_dns_record_set" "private-container-registry-cname" {
  managed_zone = google_dns_managed_zone.private-container-registry.name
  name         = "*.gcr.io."
  type         = "CNAME"
  rrdatas      = ["gcr.io."]
  ttl          = 300
}

resource "google_dns_record_set" "private-container-registry-a" {
  managed_zone = google_dns_managed_zone.private-container-registry.name
  name         = "gcr.io."
  type         = "A"
  rrdatas      = local.private_google_access_ips
  ttl          = 300
}



resource "google_dns_managed_zone" "private-artifact-registry" {
  name        = "private-artifact-registry"
  dns_name    = "pkg.dev."
  description = "Private DNS zone for Artifact Registry"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = module.fedlearn-vpc.network_id
    }
  }
}

resource "google_dns_record_set" "private-artifact-registry-cname" {
  managed_zone = google_dns_managed_zone.private-artifact-registry.name
  name         = "*.pkg.dev."
  type         = "CNAME"
  rrdatas      = ["pkg.dev."]
  ttl          = 300
}

resource "google_dns_record_set" "private-artifact-registry-a" {
  managed_zone = google_dns_managed_zone.private-artifact-registry.name
  name         = "pkg.dev."
  type         = "A"
  rrdatas      = local.private_google_access_ips
  ttl          = 300
}
