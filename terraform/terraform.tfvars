# GKE cluster name
cluster_name = "fedlearn"

# Cluster tenant names. Each tenant gets a dedicated nodepool, service accounts etc.
tenant_names = ["fltenant1"]

# GKE cluster created created in this region
region = "europe-west1"
# need to be from region above. Cluster nodes created in each zone.
zones = ["europe-west1-b"]

# Anthos Config Management
# Update with your own repo URL, if you created one
# For simplicity, repo is assumed to be publicly accessible ('none' secret)
acm_repo_location = "https://github.com/GoogleCloudPlatform/gke-third-party-apps-blueprint"
acm_secret_type   = "none"
acm_branch        = "main"
acm_dir           = "configsync"

project_id = ""
