# See the series of blog posts for details on enabling Anthos Config Management using Terraform
# https://cloud.google.com/blog/topics/anthos/using-terraform-to-enable-config-sync-on-a-gke-cluster

resource "google_gke_hub_membership" "membership" {
  membership_id = module.gke.name
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${module.gke.cluster_id}"
    }
  }
  provider = google-beta

  depends_on = [
    module.project-services
  ]
}

resource "google_gke_hub_feature" "feature" {
  name     = "configmanagement"
  location = "global"
  provider = google-beta

  depends_on = [
    module.project-services
  ]
}

resource "google_gke_hub_feature_membership" "feature_member" {
  location   = "global"
  feature    = google_gke_hub_feature.feature.name
  membership = google_gke_hub_membership.membership.membership_id
  configmanagement {
    version = var.acm_version
    config_sync {
      git {
        sync_repo   = var.acm_repo_location
        sync_branch = var.acm_branch
        policy_dir  = var.acm_dir
        secret_type = var.acm_secret_type
      }
      source_format = "unstructured"
    }
    # Note that we enable PolicyController mutations separately below
    policy_controller {
      enabled                    = true
      template_library_installed = true
    }
  }
  provider = google-beta

  depends_on = [
    module.asm.asm_wait,
  ]
}

# Execute script to enable the PoliycController Mutations (beta) feature.
# The Terraform google_gke_hub_feature_membership module above does not yet support enabling mutations,
# so we call gcloud to update the config directly.
module "enable_policycontroller_mutations" {
  source        = "terraform-google-modules/gcloud/google"
  version       = "3.1.1"
  upgrade       = false
  skip_download = true

  create_cmd_entrypoint = "./scripts/enablePolicyControllerMutations.sh"
  create_cmd_body       = google_gke_hub_feature_membership.feature_member.membership
}
