module "kms" {
  source             = "terraform-google-modules/kms/google"
  version            = "~> 2.0"

  project_id         = var.project_id
  location           = var.region
  keyring            = "keyring-${random_id.keyring_suffix.hex}"
  keys               = [var.cluster_secrets_keyname]

  # IAM
  set_encrypters_for = [var.cluster_secrets_keyname]
  set_decrypters_for = [var.cluster_secrets_keyname]
  encrypters         = ["serviceAccount:${local.gke_robot_sa}"]
  decrypters         = ["serviceAccount:${local.gke_robot_sa}"]
  prevent_destroy    = false
}

# KeyRings cannot be deleted; append a suffix to name
resource "random_id" "keyring_suffix" {
  byte_length = 4
}