terraform {
  required_version = ">=1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.20.0, <5.0.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.20.0, <5.0.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 2.2.0, < 4.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0, ~> 2.10"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.3.1, <4.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}
