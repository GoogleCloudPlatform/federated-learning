# Cross-device Federated Learning

This module is an example of an end-to-end demo for cross-device Federated Learning. This example deploys 6 different workloads:

- `aggregator`: this is a job that reads device gradients and calculates aggregated result with Differential Privacy
- `collector`: this is a job that runs periodically to query active task and encrypted gradients, resulting in deciding when to kick off aggregating
- `modelupdater`: this is a job that listens to events and publishes results so that device can download
- `task-assignment`: this is a frontend service that distributes training tasks to devices
- `task-management`: this is a job that manages tasks
- `task-scheduler`: this is a job that either runs periodically or is triggered by some events

## Infrastructure

The following diagram shows the resources that you create and configure with the blueprint.

![alt_text](../../assets/cross-device.svg "Resources created by the blueprint")

It creates:

- A spanner instance for storing the status of training
- Pubsub topics that act as buses for messages between microservices
- Buckets for storing the trained models

This blueprint is built on top of the [Federated learning blueprint](../../README.md).

### Prerequisites

- A POSIX-compliant shell
- Git (tested with version 2.41)
- Docker (tested with version 20.10.21)

### (Optional) Build the cross-device images to use in the blueprint

1. `git clone https://github.com/privacysandbox/odp-federatedcompute`
1. `git submodule update --init --recursive`
1. `gcloud builds worker-pools create odp-federatedcompute-privatepool --region us-central1 --worker-machine-type=e2-standard-32`
1. `export PROJECT_NUMBER=$(gcloud projects list --filter="$(gcloud config get project)" --format="value(PROJECT_NUMBER)")`
1. `export PROJECT_ID=$(gcloud config get project)`
1. `gcloud projects add-iam-policy-binding ${PROJECT_ID} --member=serviceAccount:"${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" --role=roles/storage.objectUser`
1. `gcloud projects add-iam-policy-binding ${PROJECT_ID} --member=serviceAccount:"${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" --role=roles/logging.logWriter`
1. `gcloud projects add-iam-policy-binding ${PROJECT_ID} --member=serviceAccount:"${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" --role=roles/artifactregistry.writer`
1. Uncomment lines 30,31
1. `gcloud builds submit --substitutions=_PROJECT_ID="${PROJECT_ID},_REGISTRY=europe-docker.pkg.dev/${PROJECT_ID}/container-image-repository" --region us-central1`

### Deploy the blueprint

This example builds on top of the infrastructure that the
[blueprint provides](../../README.md), and follows the best practices the
blueprint establishes.

To deploy the cross-device federated learning blueprint described in this document, you need to deploy the [Federated learning blueprint](../../README.md#deploy-the-blueprint) first. Then, you can deploy the cross-device federated learning blueprint described in this document.

To deploy this solution with end-to-end confidentiality:

- Set the `cross_device` Terraform variable to `true`
- Set the `enable_confidential_nodes` Terraform variable to `true`
- Set the `cluster_tenant_pool_machine_type` Terraform variable to `n2d-standard-8`
- Set the `cross_device_workloads_kubernetes_namespace` Terraform variable to prepare the namespace for future deployments
- Set the `encryption_key_service_a_base_url` Terraform variable to `https://privatekeyservice-ca-staging.rb-odp-key-host-dev.com/v1alpha`
- Set the `encryption_key_service_b_base_url` Terraform variable to `https://privatekeyservice-cb-staging.rb-odp-key-host-dev.com/v1alpha`
- Set the `encryption_key_service_a_cloudfunction_url` Terraform variable to `https://ca-staging-us-central1-encryption-key-service-clo-2q6l4c4evq-uc.a.run.app`
- Set the `encryption_key_service_b_cloudfunction_url` Terraform variable to `https://cb-staging-us-central1-encryption-key-service-clo-2q6l4c4evq-uc.a.run.app`
- Set the `wip_provider_a` Terraform variable to `projects/586348853457/locations/global/workloadIdentityPools/ca-staging-opwip-1/providers/ca-staging-opwip-pvdr-1`
- Set the `wip_provider_b` Terraform variable to `projects/586348853457/locations/global/workloadIdentityPools/cb-staging-opwip-1/providers/cb-staging-opwip-pvdr-1`
- Set the `service_account_a` Terraform variable to `ca-staging-opverifiedusr@rb-odp-key-host.iam.gserviceaccount.com`
- Set the `service_account_b` Terraform variable to `cb-staging-opverifiedusr@rb-odp-key-host.iam.gserviceaccount.com`
- Set the `allowed_operator_service_accounts` Terraform variable to `ca-staging-opallowedusr@rb-odp-key-host.iam.gserviceaccount.com,cb-staging-opallowedusr@rb-odp-key-host.iam.gserviceaccount.com`
- Set the `aggregator_image` Terraform variable to the name of the cross-device image to use
- Set the `model_updater_image` Terraform variable to the name of the cross-device image to use
- Set the `collector_image` Terraform variable to the name of the cross-device image to use
- Set the `task_assignment_image` Terraform variable to the name of the cross-device image to use
- Set the `task_management_image` Terraform variable to the name of the cross-device image to use
- Set the `task_scheduler_image` Terraform variable to the name of the cross-device image to use
- Set the `task_builder_image` Terraform variable to the name of the cross-device image to use

### Containers running in different namespaces, in the same GKE cluster

1. Provision infrastructure by following the instructions in the [main readme](../../README.md).
1. From Cloud Shell, change the working directory to the `terraform` directory.
1. Initialize the following Terraform variables:

   ```hcl
        enable_confidential_nodes                  = true
        cluster_tenant_pool_machine_type           = "n2d-standard-4"
        cluster_default_pool_machine_type          = "n2d-standard-4"
        cross_device                               = true
        encryption_key_service_a_base_url          = "https://privatekeyservice-ca-staging.rb-odp-key-host-dev.com/v1alpha"
        encryption_key_service_b_base_url          = "https://privatekeyservice-cb-staging.rb-odp-key-host-dev.com/v1alpha"
        encryption_key_service_a_cloudfunction_url = "https://ca-staging-us-central1-encryption-key-service-clo-2q6l4c4evq-uc.a.run.app"
        encryption_key_service_b_cloudfunction_url = "https://cb-staging-us-central1-encryption-key-service-clo-2q6l4c4evq-uc.a.run.app"
        wip_provider_a                             = "projects/586348853457/locations/global/workloadIdentityPools/ca-staging-opwip-1/providers/ca-staging-opwip-pvdr-1"
        wip_provider_b                             = "projects/586348853457/locations/global/workloadIdentityPools/cb-staging-opwip-1/providers/cb-staging-opwip-pvdr-1"
        service_account_a                          = "ca-staging-opverifiedusr@rb-odp-key-host.iam.gserviceaccount.com"
        service_account_b                          = "cb-staging-opverifiedusr@rb-odp-key-host.iam.gserviceaccount.com"
        allowed_operator_service_accounts          = "ca-staging-opallowedusr@rb-odp-key-host.iam.gserviceaccount.com,cb-staging-opallowedusr@rb-odp-key-host.iam.gserviceaccount.com"
   ```

1. Add the following variables with the name of the cross-device images to use:
   ```hcl
        # Confidential space
        aggregator_image    = "<aggregator_image_name>"
        model_updater_image = "<model_updater_image_name>"

        # GKE
        collector_image       = "<collector_image_name>"
        task_assignment_image = "<task_assignment_image_name>"
        task_management_image = "<task_management_image_name>"
        task_scheduler_image  = "<task_scheduler_image_name>"
        task_builder_image    = "<task_builder_image_name>"
   ```

1. Run `terraform apply`, and wait for Terraform to complete the provisioning process.

### Test the deployment

1. Get the ingress public IP : `export LB_IP=$(kubectl get svc istio-ingressgateway-cross-device -n istio-ingress --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}})"`
1. `git clone https://github.com/privacysandbox/odp-federatedcompute`
1. `git submodule update --init --recursive`
1. Once inside the `odp-federatedcompute` directory, run this command to go inside the Docker container
   `./scripts/docker/docker_sh.sh`
1. Once inside the container, create an evaluation task:
   `bazel run //java/src/it/java/com/google/ondevicepersonalization/federatedcompute/endtoendtests:end_to_end_test -- --task_management_server http://$LB_IP:8082 --server http://$LB_IP:8083 --public_key_url https://publickeyservice-ca-staging.rb-odp-key-host-dev.com/v1alpha/publicKeys`
1. Once inside the container, create and complete an evaluation task:
   `bazel run //java/src/it/java/com/google/ondevicepersonalization/federatedcompute/endtoendtests:end_to_end_test -- --task_management_server http://$LB_IP:8082 --server http://$LB_IP:8083 --public_key_url https://publickeyservice-ca-staging.rb-odp-key-host-dev.com/v1alpha/publicKeys`
