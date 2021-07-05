# GKE cluster name
cluster_name="fedlearn"

# Cluster tenant names. Each tenant gets a dedicated nodepool, service accounts etc.
tenant_names=["fltenant1"]

# GKE cluster created created in this region
region="europe-west1"
# need to be from region above. Cluster nodes created in each zone.
zones=["europe-west1-b"]

# Anthos Service Mesh version
# NOTE that ASM 1.11 is not currently supported by the Terraform module
asm_version="1.10"
# use a standardised revision label for convenience (to avoid re-labelling namespaces per patch)
asm_revision_label="asm-110"

# Anthos Config Management
# Update with your own repo URL, if you created one
# For simplicity, repo is assumed to be publicly accessible ('none' secret)
acm_repo_location="https://github.com/GoogleCloudPlatform/gke-third-party-apps-blueprint"
acm_secret_type="none"
acm_branch="main"
acm_dir="configsync"
acm_version="1.9.0"
