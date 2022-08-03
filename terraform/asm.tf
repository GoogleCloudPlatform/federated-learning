module "asm" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/asm"
  version = "22.0.0"

  channel             = var.asm_release_channel
  cluster_location    = module.gke.location
  cluster_name        = module.gke.name
  project_id          = var.project_id
  enable_mesh_feature = var.asm_enable_mesh_feature
}
