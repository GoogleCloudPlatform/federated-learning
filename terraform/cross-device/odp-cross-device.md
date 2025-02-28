# ODP Cross-Device Deployment Guide

This guide describes the order of operations then describes the various approaches to building out the cross-device environment . It is **recommended** that you review this guide before starting the cross-device  configuration and determine the best approach for your deployment. The cross-device deployment requires setting up a GCP environment that flows best practices as described in [Cross-silo and cross-device federated learning on Google Cloud | Cloud Architecture Center](https://cloud.google.com/architecture/cross-silo-cross-device-federated-learning-google-cloud)  and building images for the on-device-personalisation services (ODP) as described [On-Device Personalization \- personalization with enhanced privacy protection](https://developers.google.com/privacy-sandbox/protections/on-device-personalization) 

### Deployment Configuration

 This guide is designed to help get you started quickly with the integration of the  ODP services with the  cross-device platform . You may need to reconfigure accordingly based on your deployment requirements.

 **Configuration issues to consider:**
 - The configuration use a single spanner instance and a single database for the entire deployment. If you require multiple spanner instances and databases you will need to modify the configuration to create additional spanner instances and/or databases.
 - The configuration uses a single artifact registry for the entire deployment. If you require multiple artifact registries you will need to modify the configuration to create additional artifact registries.
 - The configuration uses a single GKE cluster for the entire deployment. If you require multiple GKE clusters you will need to modify the configuration to create additional GKE clusters.
 - The configuration uses GKE confidential nodes you may require that confidential spaces is used for the aggregation services so will need to modify the configuration to use confidential spaces. Refer to the [odp-federatedcompute repository](https://github.com/privacysandbox/odp-federatedcompute/tree/main) for more information on how to configure confidential space.
 - Client side configuration is not configurable in this deployment.  refer to the [odp-federatedcompute repository](https://github.com/privacysandbox/odp-federatedcompute/tree/main) for more information on how to configure the client side.


## Deployment Sequence

### Important: Order of Operations

The deployment must follow this specific sequence:

1. **Base Platform Deployment** (Required First)  
   Follow the instructions in [https://github.com/GoogleCloudPlatform/federated-learning/tree/main?tab=readme-ov-file\#deploy-the-blueprint](https://github.com/GoogleCloudPlatform/federated-learning/tree/main?tab=readme-ov-file#deploy-the-blueprint)  

   Make this single variable change to the base deployment prior to running the deployment:

```
set the varaiable cluster_tenant_pool_machine_type to n2d-standard-8 
```

NOTE before deploying the cross-device deployment ensure the variables in the [Cross-device FL  README are set appropriately](https://github.com/GoogleCloudPlatform/federated-learning/blob/main/terraform/cross-device/README.md) .


```

# In /federated-learning/terraform

Then run the following: 
terraform init
terraform apply
```

   This creates:

   

   - Artifact Registry repository  
   - GKE cluster  
   - Required IAM roles  
   - Other base infrastructure

   

2. **Image Building** (After Artifact Registry exists)  
   The images depends on the following repo [https://github.com/privacysandbox/odp-federatedcompute](https://github.com/privacysandbox/odp-federatedcompute)   
   Following [https://github.com/privacysandbox/odp-federatedcompute/blob/main/BUILDING.md](https://github.com/privacysandbox/odp-federatedcompute/blob/main/BUILDING.md) 

```
# In /odp-federatedcompute
./scripts/docker/docker_sh.sh
./scripts/build_images.sh
```

   - Images will be pushed to the Artifact Registry created in step 1  
   - Skip this step if using pre-built images from another project  
   - You will not be able to build the images using a cloudshell instance due to resource  it is recommended to use a VM with 1TD of storage

   

3. **Cross-Device Platform Deployment** (After images are available)

```
# In /federated-learning/terraform
# Update main.tf with correct image references first
terraform apply
```

### Warning

- Do not attempt to deploy the cross-device platform before the base infrastructure is ready  
- Ensure images are built and available before deploying the cross-device  platform  
- If using images from another project, ensure permissions are configured before platform deployment

## Prerequisites

- Base platform and Artifact Registry deployed via root Terraform configuration  
- Docker installed  
- Access to GCP project  
- Terraform installed

## Approach 1: Manual Deployment (Recommended for Deterministic Builds)

### 1\. Build Images Using Docker

First, build the images using the deterministic Docker environment:

```
# Navigate to odp-federatedcompute
cd ../../odp-federatedcompute

# Use the provided Docker shell script for deterministic builds
./scripts/docker/docker_sh.sh

# Inside the Docker shell, build the images
./scripts/build_images.sh
```

### 2\. Create terraform.tfvars

After building the images, create `terraform.tfvars` in the cross-device directory with the image references:

```
# Replace us-central1 with the approriate region and  PROJECT_ID with your GCP project ID
aggregator_image = "us-central1-docker.pkg.dev/PROJECT_ID/container-image-repository/aggregator:latest"
collector_image = "us-central1-docker.pkg.dev/PROJECT_ID/container-image-repository/collector:latest"
model_updater_image = "us-central1-docker.pkg.dev/PROJECT_ID/container-image-repository/model-updater:latest"
task_assignment_image = "us-central1-docker.pkg.dev/PROJECT_ID/container-image-repository/task-assignment:latest"
task_management_image = "us-central1-docker.pkg.dev/PROJECT_ID/container-image-repository/task-management:latest"
task_scheduler_image = "us-central1-docker.pkg.dev/PROJECT_ID/container-image-repository/task-scheduler:latest"
```

### 3\. Deploy Cross-Device Platform

```
# set the variables required as decribed here:\ https://github.com/privacysandbox/odp-federatedcompute/blob/main/BUILDING.md

cd federated-learning/terraform/cross-device
terraform init
terraform apply
```

## Approach 2: Automated Deployment Using deploy.sh

The `federated-learning/terraform/scripts/deploy.sh` script is a helper script that automates the process using the  Docker build environment. 

### 1\. Run Automated Deployment

```
# Navigate to terraform directory
cd federated-learning/terraform

# Run deployment script
./scripts/deploy.sh

# Script will:
# 1. Build images directly (not using the deterministic Docker environment)
# 2. Push images to Artifact Registry
# 3. Generate terraform.tfvars
# 4. Prepare for terraform apply
```

### 2\. Complete Deployment

```
cd cross-device
terraform init
terraform apply
```

## Important Notes

- **For Production**: Use Approach 1 with the deterministic Docker build environment  
- **For Development**: Approach 2 using deploy.sh can be used for faster iterations  
- The deploy.sh script bypasses the deterministic build environment provided by `docker_sh.sh`

## Verification

After deployment, verify:

1. Images exist in Artifact Registry  
2. Services are running in GKE  
3. Cross-device platform is operational

## Troubleshooting

Common issues:

- Ensure Artifact Registry is created before building images  
- Verify the Docker shell script executed successfully  
- Check service account permissions  
- Verify image references in terraform.tfvars match registry path

## Notes

- Using the provided Docker shell script ensures deterministic builds  
- The build process uses Bazel within the Docker environment  
- All dependencies are managed within the Docker container

## Image Variable Configuration

There are two approaches to configure the image references:

### Approach 1: Using terraform.tfvars (Override Method)

Create `terraform.tfvars` in the root terraform directory (`/federated-learning/terraform/`):

```
# Replace us-central1 with the approriate region and  PROJECT_ID with your GCP project ID
# /federated-learning/terraform/terraform.tfvars
aggregator_image = "us-central1-docker.pkg.dev/PROJECT_ID/container-image-repository/aggregator:latest"
collector_image = "us-central1-docker.pkg.dev/PROJECT_ID/container-image-repository/collector:latest"
model_updater_image = "us-central1-docker.pkg.dev/PROJECT_ID/container-image-repository/model-updater:latest"
task_assignment_image = "us-central1-docker.pkg.dev/PROJECT_ID/container-image-repository/task-assignment:latest"
task_management_image = "us-central1-docker.pkg.dev/PROJECT_ID/container-image-repository/task-management:latest"
task_scheduler_image = "us-central1-docker.pkg.dev/PROJECT_ID/container-image-repository/task-scheduler:latest"
```

This will override the placeholder "debian" values in main.tf.

### Approach 2: Modifying main.tf Variables (Direct Method)

Instead of creating a separate tfvars file, update the cross-device module in main.tf:

```
# Replace us-central1 with the approriate region 
# /federated-learning/terraform/main.tf
module "cross_device" {
  count                    = var.cross_device ? 1 : 0
  source                   = "./cross-device"
  
  # Replace placeholder values with actual image references
  aggregator_image         = "us-central1-docker.pkg.dev/${data.google_project.project.project_id}/container-image-repository/aggregator:latest"
  collector_image          = "us-central1-docker.pkg.dev/${data.google_project.project.project_id}/container-image-repository/collector:latest"
  model_updater_image      = "us-central1-docker.pkg.dev/${data.google_project.project.project_id}/container-image-repository/model-updater:latest"
  task_management_image    = "us-central1-docker.pkg.dev/${data.google_project.project.project_id}/container-image-repository/task-management:latest"
  task_assignment_image    = "us-central1-docker.pkg.dev/${data.google_project.project.project_id}/container-image-repository/task-assignment:latest"
  task_scheduler_image     = "us-central1-docker.pkg.dev/${data.google_project.project.project_id}/container-image-repository/task-scheduler:latest"
  
  # ... other variables remain the same ...
}
```

### Recommended Approach

The direct method (Approach 2\) is recommended because:

1. Keeps all configuration in one place  
2. Uses project ID interpolation  
3. Makes the deployment process more straightforward  
4. Avoids multiple configuration files

## Deployment Steps with Direct Method

1. Build images using the deterministic Docker environment:

```
cd odp-federatedcompute
./scripts/docker/docker_sh.sh
./scripts/build_images.sh
```

2. Deploy using root terraform configuration:

```
cd ../federated-learning/terraform
terraform init
terraform apply
```

## Notes

- The placeholder "debian" values in main.tf should be replaced with actual image references  
- Using interpolation (`${data.google_project.project.project_id}`) ensures correct project ID  
- No need for separate terraform.tfvars when using the direct method

## Cross-Project Image Configuration

When your images are stored in a different project from where you're deploying the platform:

### 1\. Configure Image Project Access

Ensure the deployment project has access to the Artifact Registry in the images project:

```
# Grant access to the deployment project's service account
gcloud artifacts repositories add-iam-policy-binding container-image-repository \
    --project=IMAGE_PROJECT_ID \
    --location=europe-west1 \
    --member="serviceAccount:${DEPLOYMENT_PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
    --role="roles/artifactregistry.reader"
```

Note if you encounter setting 

### 2\. Update Image References in main.tf

Modify the cross-device module in main.tf to reference the images project:

```
# /federated-learning/terraform/main.tf
module "cross_device" {
  count                    = var.cross_device ? 1 : 0
  source                   = "./cross-device"
  
# Reference images from separate project
# Replace us-central1 with the approriate region
  aggregator_image         = "us-central1-docker.pkg.dev/IMAGE_PROJECT_ID/container-image-repository/aggregator:latest"
  collector_image          = "us-central1-docker.pkg.dev/IMAGE_PROJECT_ID/container-image-repository/collector:latest"
  model_updater_image      = "us-central1-docker.pkg.dev/IMAGE_PROJECT_ID/container-image-repository/model-updater:latest"
  task_management_image    = "us-central1-docker.pkg.dev/IMAGE_PROJECT_ID/container-image-repository/task-management:latest"
  task_assignment_image    = "us-central1-docker.pkg.dev/IMAGE_PROJECT_ID/container-image-repository/task-assignment:latest"
  task_scheduler_image     = "us-central1-docker.pkg.dev/IMAGE_PROJECT_ID/container-image-repository/task-scheduler:latest"
  
  # Deployment project variables
  project_id               = data.google_project.project.project_id
  # ... other variables remain the same ...
}
```

### 3\. Add Image Project Variable (Optional)

For better maintainability, you can add a variable for the image project:

```
# /federated-learning/terraform/variables.tf
variable "image_project_id" {
  description = "Project ID where ODP service images are stored"
  type        = string
}

# /federated-learning/terraform/main.tf
module "cross_device" {
  # ... other configuration ...
  aggregator_image         = "us-central1-docker.pkg.dev/${var.image_project_id}/container-image-repository/aggregator:latest"
  collector_image          = "us-central1-docker.pkg.dev/${var.image_project_id}/container-image-repository/collector:latest"
  # ... other image variables ...
}
```

### 4\. Required IAM Permissions

Ensure the following permissions are set up:

1. Deployment project's service account needs `artifactregistry.reader` role in the images project  
2. GKE nodes need permission to pull images from the separate project  
3. Workload identity configuration if using workload identity

```
# Grant GKE node service account access to images
gcloud artifacts repositories add-iam-policy-binding container-image-repository \
    --project=IMAGE_PROJECT_ID \
    --location=us-central1 \
    --member="serviceAccount:DEPLOYMENT_PROJECT_ID.svc.id.goog[odp-federated/default]" \
    --role="roles/artifactregistry.reader"
```

Note: there are 4 service accounts created by the deployment you can add all four to the target project and grant the artifactregistry.reader to all four service accounts

## Verification for Cross-Project Setup

1. Verify image access:

```
# List images in source project
gcloud artifacts docker images list \
    us-central1-docker.pkg.dev/IMAGE_PROJECT_ID/container-image-repository \
    --project=IMAGE_PROJECT_ID
```

2. Test image pull:

```
# Try pulling an image using deployment project credentials
docker pull us-central1-docker.pkg.dev/IMAGE_PROJECT_ID/container-image-repository/aggregator:latest
```

## Troubleshooting Cross-Project Setup

Common issues:

- IAM permission errors when pulling images  
- Workload identity configuration issues  
- Missing repository access  
- Network connectivity between projects

Check:

1. IAM bindings are correct  
2. Service accounts have necessary permissions  
3. Network policies allow cross-project access  
4. Artifact Registry API is enabled in both projects

## Phased Deployment Approach

### Option: Platform First, Images Later

If you need to deploy the cross-device platform infrastructure before building/deploying images:

1. **Ensure that the deploy\_services variable is set to false**

```
# /federated-learning/terraform/main.tf

  
  # Set to false to skip service deployments
  deploy_services          = false  #
  
  # Use placeholder values for images
  aggregator_image         = "debian"
  collector_image          = "debian"
  model_updater_image      = "debian"
  task_management_image    = "debian"
  task_assignment_image    = "debian"
  task_scheduler_image     = "debian"
  
  # ... other variables remain the same ...
}
```

### Deployment Sequence

1. **Initial Platform Deployment**

```
# In /federated-learning/terraform
terraform init
terraform apply
```

This deploys:

- Base infrastructure  
- Cross-device platform components  
- Skips service deployments  
2. **Later: Build and Deploy Images** When ready to deploy services:

a. Build images:

```
cd odp-federatedcompute
./scripts/docker/docker_sh.sh
./scripts/build_images.sh
```

b. Update [main.tf](http://main.tf) with location of images:

```
module "cross_device" {
  # ... other configuration ...
  deploy_services          = true  # Enable service deployment
  
  # Update with actual image references
  aggregator_image         = "us-central1-docker.pkg.dev/${data.google_project.project.project_id}/container-image-repository/aggregator:latest"
  collector_image          = "us-central1-docker.pkg.dev/${data.google_project.project.project_id}/container-image-repository/collector:latest"
  # ... other image references ...
}
```

c. Apply changes:

```
terraform apply
```

### Benefits of This Approach

- Allows platform infrastructure to be deployed independently  
- Enables image building and testing without blocking platform deployment  
- Provides flexibility in service rollout timing

### Important Notes

- All infrastructure dependencies will still be created  
- Services won't be deployed until `deploy_services = true`  
- Image references can be updated without affecting other infrastructure  
- Useful for staging environments or phased deployments

