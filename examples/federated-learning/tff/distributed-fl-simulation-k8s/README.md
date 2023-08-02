# Image classification tutorial example

In this directory, you can find an example of the
[High-Performance Simulation with Kubernetes](https://www.tensorflow.org/federated/tutorials/high_performance_simulation_with_kubernetes)
tutorial.

This example runs on a single host.

## Prerequisites

- A POSIX-compliant shell
- Git (tested with version 2.41)
- Docker (tested with version 20.10.21)
- Docker Compose (tested with version 1.29.2)

## How to run

You can run this example in two different runtime environments:

- Two workers and a coordinator running in different containers on the same host.
- Two workers and a coordinator running in different containers in different GKE clusters.

### Containers running on the same host

To run this example, build the container images and run containers:

```sh
docker compose \
    --file compose.yaml \
    up \
    --abort-on-container-exit \
    --build \
    --exit-code-from tff-client
```

### Containers running in different GKE clusters

1. Provision infrastructure by following the instructions in the [main README](../../../../README.md).
1. From Cloud Shell, change the working directory to the root of this repository.
1. Render the Kpt package for the first worker:

    ```sh
    examples/federated-learning/tff/distributed-fl-simulation-k8s/generate-example-tff-workload-descriptors.sh \
        "$(terraform -chdir="<PATH_TO_WORKER_1_TERRAFORM_DIRECTORY>" output -raw config_sync_repository_path)/tenants/fltenant1" \
        examples/federated-learning/tff/distributed-fl-simulation-k8s/distributed-fl-workload-pkg \
        "fltenant1" \
        "$(terraform -chdir="<PATH_TO_WORKER_1_TERRAFORM_DIRECTORY>" output -raw kubernetes_apps_service_account_name)" \
        "emnist_partition_1.sqlite" \
        "not-needed" \
        "not-needed"
    ```

    Where `<PATH_TO_WORKER_1_TERRAFORM_DIRECTORY>` is the path to the Terraform
    directory where you stored the Terraform descriptors to provision the cloud
    environment for the first worker.

1. Commit changes to the first worker Config Sync repository.
1. Render the Kpt package for the second worker:

    ```sh
    examples/federated-learning/tff/distributed-fl-simulation-k8s/generate-example-tff-workload-descriptors.sh \
        "$(terraform -chdir="<PATH_TO_WORKER_2_TERRAFORM_DIRECTORY>" output -raw config_sync_repository_path)/tenants/fltenant1" \
        examples/federated-learning/tff/distributed-fl-simulation-k8s/distributed-fl-workload-pkg \
        "fltenant1" \
        "$(terraform -chdir="<PATH_TO_WORKER_2_TERRAFORM_DIRECTORY>" output -raw kubernetes_apps_service_account_name)" \
        "emnist_partition_2.sqlite" \
        "not-needed" \
        "not-needed"
    ```

    Where `<PATH_TO_WORKER_2_TERRAFORM_DIRECTORY>` is the path to the Terraform
    directory where you stored the Terraform descriptors to provision the cloud
    environment for the second worker.

1. Commit changes to the second worker Config Sync repository.
1. Render the Kpt package for the coordinator:

    ```sh
    examples/federated-learning/tff/distributed-fl-simulation-k8s/generate-example-tff-workload-descriptors.sh \
        "$(terraform -chdir="<PATH_TO_COORDINATOR_TERRAFORM_DIRECTORY>" output -raw config_sync_repository_path)/tenants/main" \
        examples/federated-learning/tff/distributed-fl-simulation-k8s/distributed-fl-workload-pkg \
        "main" \
        "$(terraform -chdir="<PATH_TO_COORDINATOR_TERRAFORM_DIRECTORY>" output -raw kubernetes_apps_service_account_name)" \
        "not-needed" \
        "$(terraform -chdir="<PATH_TO_WORKER_1_TERRAFORM_DIRECTORY>" output -raw tff_example_worker_external_ip_address)" \
        "$(terraform -chdir="<PATH_TO_WORKER_2_TERRAFORM_DIRECTORY>" output -raw tff_example_worker_external_ip_address)" \
        "true"
    ```

    Where:
        - `<PATH_TO_COORDINATOR_TERRAFORM_DIRECTORY>` is the path to the
            Terraform directory where you stored the Terraform descriptors to
            provision the cloud environment for the second worker.
        - `<PATH_TO_WORKER_1_TERRAFORM_DIRECTORY>` is the path to the Terraform
            directory where you stored the Terraform descriptors to provision
            the cloud environment for the first worker.
        - `<PATH_TO_WORKER_2_TERRAFORM_DIRECTORY>` is the path to the Terraform
            directory where you stored the Terraform descriptors to provision
            the cloud environment for the second worker.

1. Commit changes to the coordinator Config Sync repository.
