module "asm" {
  source                = "terraform-google-modules/kubernetes-engine/google//modules/asm"

  asm_version           = var.asm_version
  revision_name         = var.asm_revision_label
  project_id            = var.project_id
  cluster_name          = module.gke.name
  location              = module.gke.location
  cluster_endpoint      = module.gke.endpoint

  managed_control_plane = false
  enable_all            = false
  enable_cluster_roles  = false
  enable_cluster_labels = false
  enable_gcp_apis       = false
  enable_gcp_iam_roles  = false
  enable_gcp_components = false
  enable_registration   = false
  # create istio-system namespace
  enable_namespace_creation = true
  # enable egress gateway, remove the ingress gateway (not required)
  options               = ["egressgateways", "no-default-ingress", "envoy-access-log"]
  skip_validation       = true
  outdir                = "./install_asm_${var.asm_version}_${module.gke.name}_outdir"
}
