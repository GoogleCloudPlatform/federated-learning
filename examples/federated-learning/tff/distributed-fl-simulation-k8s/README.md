# Image classification tutorial example

In this directory, you can find an example running a TensorFlow Federated
training process in different runtime environments. This example deploys two
kinds of workloads:

- `coordinator`: coordinates the training effort, and collects the result of the
  training from workers.
- `workers` that waits for instructions from the coordinator, runs the assigned
  model training, and sends training results back to the coordinator.

In the current implementation:

- Workers wait to be assigned a training job by the coordinator, complete
  training jobs, and send training results back to the coordinator.
- The coordinator sends training jobs to workers, collects training results from
  workers, and reports relevant output. Once the training effort completes,
  the coordinator stops, and runs again after a few seconds, in a loop.

This example builds on top of the infrastructure that the
[blueprint provides](../../../../README.md), and follows the best practices the
blueprint establishes.

This example is based on the
[High-Performance TensorFlow Federated Simulation with Kubernetes](https://www.tensorflow.org/federated/tutorials/high_performance_simulation_with_kubernetes)
tutorial.

## Prerequisites

- A POSIX-compliant shell
- Git (tested with version 2.41)
- Docker (tested with version 20.10.21)

## How to run

You can run this example in different runtime environments:

- Two workers and a coordinator running in different containers, each in a
  dedicated Kubernetes Namespace, in the same Google Kubernetes Engine (GKE)
  cluster. For example, a cloud platform administrator can follow this
  approach to validate how the workload behaves in a GKE cluster across
  different namespaces to simulate a distributed federated learning
  environment, without having to provision and configure different Kubernetes
  clusters.
- Two workers and a coordinator running in different containers in different
  GKE clusters. For example, a cloud platform administrator can follow this
  approach to deploy the workload in an environment that more closely
  resembles a production one.

### Containers running in different namespaces, in the same GKE cluster

1. Provision infrastructure by following the instructions in the [main readme](../../../../README.md).

1. From Cloud Shell, change the working directory to the `terraform` directory.

1. Initialize the following Terraform variables for the workers:

   ```hcl
   tenant_names = ["fltenant1", "fltenant2", "fltenant3"]
   ```

1. Run `terraform apply`, and wait for Terraform to complete the provisioning process.

1. [Build the example container image, and push it to the container image registry](#build-the-example-container-image-and-push-it-to-the-container-image-registry).

1. Generate general configuration files:

   ```sh
   "../examples/federated-learning/tff/distributed-fl-simulation-k8s/scripts/copy-tff-example-mesh-wide-content.sh" \
     "../examples/federated-learning/tff/distributed-fl-simulation-k8s/mesh-wide" \
     "$(terraform output -raw acm_config_sync_configuration_destination_directory_path)/example-tff-image-classification-mesh-wide" \
     "false" \
     "false" \
     "true"
   ```

1. Generate configuration files for the first worker:

   ```sh
   "../examples/federated-learning/tff/distributed-fl-simulation-k8s/scripts/generate-tff-example-acm-tenant-content.sh" \
     "$(terraform output -raw acm_config_sync_tenants_configuration_destination_directory_path)" \
     "fltenant1" \
     "../examples/federated-learning/tff/distributed-fl-simulation-k8s/distributed-fl-workload-pkg" \
     "false" \
     "emnist_part_1.sqlite" \
     "not-needed" \
     "not-needed" \
     "ksa" \
     "fltenant3" \
     "false" \
     "false" \
     "$(terraform output -raw container_image_repository_fully_qualified_hostname)/$(terraform output -raw container_image_repository_name)/tff-runtime:0.0.1"
   ```

1. Generate configuration files for the second worker:

   ```sh
   "../examples/federated-learning/tff/distributed-fl-simulation-k8s/scripts/generate-tff-example-acm-tenant-content.sh" \
     "$(terraform output -raw acm_config_sync_tenants_configuration_destination_directory_path)" \
     "fltenant2" \
     "../examples/federated-learning/tff/distributed-fl-simulation-k8s/distributed-fl-workload-pkg" \
     "false" \
     "emnist_part_2.sqlite" \
     "not-needed" \
     "not-needed" \
     "ksa" \
     "fltenant3" \
     "false" \
     "false" \
     "$(terraform output -raw container_image_repository_fully_qualified_hostname)/$(terraform output -raw container_image_repository_name)/tff-runtime:0.0.1"
   ```

1. Commit and push generated configuration files to the environment
   configuration repository:

   ```sh
   ACM_REPOSITORY_PATH="$(terraform output -raw acm_repository_path)"
   git -C "${ACM_REPOSITORY_PATH}" add .
   git -C "${ACM_REPOSITORY_PATH}" commit -m "Config update: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
   git -C "${ACM_REPOSITORY_PATH}" push -u origin "${ACM_BRANCH}"
   ```

1. Open the [GKE Workloads Dashboard](https://cloud.google.com/kubernetes-engine/docs/concepts/dashboards#workloads)
   and wait for the workers Deployments and Services to be ready.

1. Generate configuration files for the coordinator:

   ```sh
   "../examples/federated-learning/tff/distributed-fl-simulation-k8s/scripts/generate-tff-example-acm-tenant-content.sh" \
     "$(terraform output -raw acm_config_sync_tenants_configuration_destination_directory_path)" \
     "fltenant3" \
     "../examples/federated-learning/tff/distributed-fl-simulation-k8s/distributed-fl-workload-pkg" \
     "true" \
     "not-needed" \
     "tff-worker.fltenant1.svc.cluster.local" \
     "tff-worker.fltenant2.svc.cluster.local" \
     "ksa" \
     "fltenant3" \
     "false" \
     "false" \
     "$(terraform output -raw container_image_repository_fully_qualified_hostname)/$(terraform output -raw container_image_repository_name)/tff-runtime:0.0.1"
   ```

1. Commit and push generated configuration files to the environment
   configuration repository:

   ```sh
   ACM_REPOSITORY_PATH="$(terraform output -raw acm_repository_path)"
   git -C "${ACM_REPOSITORY_PATH}" add .
   git -C "${ACM_REPOSITORY_PATH}" commit -m "Config update: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
   git -C "${ACM_REPOSITORY_PATH}" push -u origin "${ACM_BRANCH}"
   ```

1. Wait for GKE to report the coordinator and the workers as `Ready` in the
   [GKE Workloads dashboard](https://cloud.google.com/kubernetes-engine/docs/concepts/dashboards#workloads).

### Containers running in different GKE clusters

1. Provision infrastructure by following the instructions in the [main readme](../../../../README.md)
   to provision and configure the environment for the first worker in a dedicated Google Cloud project.

1. Provision infrastructure by following the instructions in the [main readme](../../../../README.md)
   to provision and configure the environment for the second worker in a dedicated Google Cloud project.

1. Provision infrastructure by following the instructions in the [main readme](../../../../README.md)
   to provision and configure the environment for the coordinator in a dedicated Google Cloud project.

1. From Cloud Shell, change the working directory to the `terraform` directory that you used to provision
   the resources for the first worker.

1. [Build the example container image, and push it to the container image registry](#build-the-example-container-image-and-push-it-to-the-container-image-registry).

1. Generate general configuration files:

   ```sh
   "../examples/federated-learning/tff/distributed-fl-simulation-k8s/scripts/copy-tff-example-mesh-wide-content.sh" \
     "../examples/federated-learning/tff/distributed-fl-simulation-k8s/mesh-wide" \
     "$(terraform output -raw acm_config_sync_configuration_destination_directory_path)/example-tff-image-classification-mesh-wide" \
     "true" \
     "true" \
     "false"
   ```

1. Initialize the configuration for the first worker:

   ```sh
   "../examples/federated-learning/tff/distributed-fl-simulation-k8s/scripts/generate-tff-example-acm-tenant-content.sh" \
     "$(terraform output -raw acm_config_sync_tenants_configuration_destination_directory_path)" \
     "fltenant1" \
     "../examples/federated-learning/tff/distributed-fl-simulation-k8s/distributed-fl-workload-pkg" \
     "false" \
     "emnist_part_1.sqlite" \
     "not-needed" \
     "not-needed" \
     "ksa" \
     "istio-ingress" \
     "true" \
     "false" \
     "$(terraform output -raw container_image_repository_fully_qualified_hostname)/$(terraform output -raw container_image_repository_name)/tff-runtime:0.0.1"
   ```

1. Commit and push generated configuration files to the environment
   configuration repository:

   ```sh
   ACM_REPOSITORY_PATH="$(terraform output -raw acm_repository_path)"
   git -C "${ACM_REPOSITORY_PATH}" add .
   git -C "${ACM_REPOSITORY_PATH}" commit -m "Config update: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
   git -C "${ACM_REPOSITORY_PATH}" push -u origin "${ACM_BRANCH}"
   ```

1. From Cloud Shell, change the working directory to the `terraform` directory that you used to provision
   the resources for the second worker.

1. [Build the example container image, and push it to the container image registry](#build-the-example-container-image-and-push-it-to-the-container-image-registry).

1. Generate general configuration files:

   ```sh
   "../examples/federated-learning/tff/distributed-fl-simulation-k8s/scripts/copy-tff-example-mesh-wide-content.sh" \
     "../examples/federated-learning/tff/distributed-fl-simulation-k8s/mesh-wide" \
     "$(terraform output -raw acm_config_sync_configuration_destination_directory_path)/example-tff-image-classification-mesh-wide" \
     "true" \
     "true" \
     "false"
   ```

1. Initialize the following Terraform variables for the second worker:

   ```hcl
   distributed_tff_example_deploy_ingress_gateway = true
   ```

   ```sh
   "../examples/federated-learning/tff/distributed-fl-simulation-k8s/scripts/generate-tff-example-acm-tenant-content.sh" \
     "$(terraform output -raw acm_config_sync_tenants_configuration_destination_directory_path)" \
     "fltenant1" \
     "../examples/federated-learning/tff/distributed-fl-simulation-k8s/distributed-fl-workload-pkg" \
     "false" \
     "emnist_part_2.sqlite" \
     "not-needed" \
     "not-needed" \
     "ksa" \
     "istio-ingress" \
     "true" \
     "false" \
     "$(terraform output -raw container_image_repository_fully_qualified_hostname)/$(terraform output -raw container_image_repository_name)/tff-runtime:0.0.1"
   ```

1. Commit and push generated configuration files to the environment
   configuration repository:

   ```sh
   ACM_REPOSITORY_PATH="$(terraform output -raw acm_repository_path)"
   git -C "${ACM_REPOSITORY_PATH}" add .
   git -C "${ACM_REPOSITORY_PATH}" commit -m "Config update: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
   git -C "${ACM_REPOSITORY_PATH}" push -u origin "${ACM_BRANCH}"
   ```

1. Open the [GKE Workloads Dashboard](https://cloud.google.com/kubernetes-engine/docs/concepts/dashboards#workloads)
   and wait for the workers Deployments and Services to be ready.
1. From Cloud Shell, change the working directory to the `terraform` directory that you used to provision
   the resources for the coordinator.
1. [Build the example container image, and push it to the container image registry](#build-the-example-container-image-and-push-it-to-the-container-image-registry).

1. Initialize the following Terraform variables for the coordinator:

   ```hcl
   distributed_tff_example_worker_1_address = "<WORKER_1_SERVICE_IP_ADDRESS>"
   distributed_tff_example_worker_2_address = "<WORKER_2_SERVICE_IP_ADDRESS>"
   ```

   Where:

   - `<WORKER_1_SERVICE_IP_ADDRESS>` is the IP address of the load balancer
     that exposes the first worker workloads.
   - `<WORKER_2_SERVICE_IP_ADDRESS>` is the IP address of the load balancer
     that exposes the second worker workloads.

1. Run `terraform apply`.

1. Generate general configuration files:

   ```sh
   "../examples/federated-learning/tff/distributed-fl-simulation-k8s/scripts/copy-tff-example-mesh-wide-content.sh" \
     "../examples/federated-learning/tff/distributed-fl-simulation-k8s/mesh-wide" \
     "$(terraform output -raw acm_config_sync_configuration_destination_directory_path)/example-tff-image-classification-mesh-wide" \
     "false" \
     "true" \
     "true"
   ```

1. Initialize the following Terraform variables for the coordinator:

   ```sh
   "../examples/federated-learning/tff/distributed-fl-simulation-k8s/scripts/generate-tff-example-acm-tenant-content.sh" \
     "$(terraform output -raw acm_config_sync_tenants_configuration_destination_directory_path)" \
     "fltenant1" \
     "../examples/federated-learning/tff/distributed-fl-simulation-k8s/distributed-fl-workload-pkg" \
     "true" \
     "not-needed" \
     "tff-worker-1.tensorflow-federated.example.com" \
     "tff-worker-2.tensorflow-federated.example.com" \
     "ksa" \
     "fltenant1" \
     "false" \
     "true" \
     "$(terraform output -raw container_image_repository_fully_qualified_hostname)/$(terraform output -raw container_image_repository_name)/tff-runtime:0.0.1"
   ```

1. Commit and push generated configuration files to the environment
   configuration repository:

   ```sh
   ACM_REPOSITORY_PATH="$(terraform output -raw acm_repository_path)"
   git -C "${ACM_REPOSITORY_PATH}" add .
   git -C "${ACM_REPOSITORY_PATH}" commit -m "Config update: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
   git -C "${ACM_REPOSITORY_PATH}" push -u origin "${ACM_BRANCH}"
   ```

1. Wait for GKE to report the coordinator and the workers as `Ready` in the
   [GKE Workloads dashboard](https://cloud.google.com/kubernetes-engine/docs/concepts/dashboards#workloads)
   in their respective GKE clusters.

### Build the example container image, and push it to the container image registry

1. Build the example container image locally on your host:

   ```sh
   DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_REPOSITORY_HOSTNAME="$(terraform output -raw container_image_repository_fully_qualified_hostname)"
   DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_LOCALIZED_ID="${DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_REPOSITORY_HOSTNAME}/$(terraform output -raw container_image_repository_name)/tff-runtime:0.0.1"
   DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_BUILD_CONTEXT_PATH="examples/federated-learning/tff/distributed-fl-simulation-k8s/container-image"

   docker build \
     --file "${DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_BUILD_CONTEXT_PATH}/Dockerfile" \
     --tag "${DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_LOCALIZED_ID}" \
     "${DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_BUILD_CONTEXT_PATH}"
   ```

1. Authenticate Docker with the Artifact Registry repository:

   ```sh
   gcloud auth configure-docker \
       "${DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_REPOSITORY_HOSTNAME}"
   ```

1. Push the container image to the Artifact Registry repository:

   ```sh
   docker image push "${DISTRIBUTED_TFF_EXAMPLE_CONTAINER_IMAGE_LOCALIZED_ID}"
   ```

## Expected output

After deploying the workers and the coordinator, you can inspect the logs that
the coordinator produces to ensure that it connected to workers, and that workers
are running the training. The coordinator output log is similar to the following:

```plain text
round  1, metrics=OrderedDict([('sparse_categorical_accuracy', 0.10557769), ('loss', 12.475689), ('num_examples', 5020), ('num_batches', 5020)])
round  2, metrics=OrderedDict([('sparse_categorical_accuracy', 0.11940298), ('loss', 10.497084), ('num_examples', 5360), ('num_batches', 5360)])
round  3, metrics=OrderedDict([('sparse_categorical_accuracy', 0.16223507), ('loss', 7.569645), ('num_examples', 5190), ('num_batches', 5190)])
round  4, metrics=OrderedDict([('sparse_categorical_accuracy', 0.2648384), ('loss', 6.0947175), ('num_examples', 5105), ('num_batches', 5105)])
round  5, metrics=OrderedDict([('sparse_categorical_accuracy', 0.29003084), ('loss', 6.2815433), ('num_examples', 4865), ('num_batches', 4865)])
round  6, metrics=OrderedDict([('sparse_categorical_accuracy', 0.40237388), ('loss', 4.630901), ('num_examples', 5055), ('num_batches', 5055)])
round  7, metrics=OrderedDict([('sparse_categorical_accuracy', 0.4288425), ('loss', 4.2358975), ('num_examples', 5270), ('num_batches', 5270)])
round  8, metrics=OrderedDict([('sparse_categorical_accuracy', 0.46349892), ('loss', 4.3829923), ('num_examples', 4630), ('num_batches', 4630)])
round  9, metrics=OrderedDict([('sparse_categorical_accuracy', 0.492094), ('loss', 3.8121278), ('num_examples', 4680), ('num_batches', 4680)])
round 10, metrics=OrderedDict([('sparse_categorical_accuracy', 0.5872674), ('loss', 3.058461), ('num_examples', 5105), ('num_batches', 5105)])
```

## Development environment

If you want to configure a development environment for this example workload,
you can configure two workers and a coordinator running in different containers
on the same host.

Prerequisities:

- The ones listed [above](#prerequisites)
- Docker Compose (tested with version 1.29.2)

To run this example, build the container images and run containers:

```sh
docker compose \
    --file compose.yaml \
    up \
    --abort-on-container-exit \
    --build \
    --exit-code-from tff-client
```
