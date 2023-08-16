# Image classification tutorial example

In this directory, you can find an example of the
[High-Performance Simulation with Kubernetes](https://www.tensorflow.org/federated/tutorials/high_performance_simulation_with_kubernetes)
tutorial.

This example runs on a single host.

## Prerequisites

- A POSIX-compliant shell
- Git (tested with version 2.41)
- Docker (tested with version 20.10.21)

## How to run

You can run this example in two different runtime environments:

- Two workers and a coordinator running in different containers on the same host.
- Two workers and a coordinator running in different containers in different GKE clusters.

### Containers running on the same host

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

### Containers running in different namespaces, in the same GKE cluster

1. Provision infrastructure by following the instructions in the [main README](../../../../README.md).
1. From Cloud Shell, change the working directory to the `terraform` directory.
1. Initialize the following Terraform variables for the workers:

    ```hcl
    tenant_names = ["fltenant1", "fltenant2", "fltenant3"]

    distributed_tff_example_configuration          = {
        "fltenant1": {
            emnist_partition_file_name = "emnist_part_1.sqlite"
        },
        "fltenant2": {
            emnist_partition_file_name = "emnist_part_2.sqlite"
        }
    }
    ```

1. Run `terraform apply`, and wait for Terraform to complete the provisioning process, and the
    workers to be up and running, and the load balancers to have IP addresses assigned.
1. Configure the coordinator by adding the following element to the
    `distributed_tff_example_configuration` map:

    ```hcl
    "fltenant3": {
        is_coordinator = true
        worker_1_address = "tff-worker.fltenant1"
        worker_2_address = "tff-worker.fltenant2"
    }

    distributed_tff_example_coordinator_namespace = "fltenant3"
    ```

1. Run `terraform apply`.

### Containers running in different GKE clusters

1. Provision infrastructure by following the instructions in the [main README](../../../../README.md).
1. From Cloud Shell, change the working directory to the `terraform` directory that you used to provision
    the resources for the first worker.
1. Initialize the following Terraform variables for the first worker:

    ```hcl
    distributed_tff_example_deploy_ingress_gateway = true
    distributed_tff_example_configuration          = {
        "fltenant1": {
            emnist_partition_file_name = "emnist_part_1.sqlite"
        }
    }
    ```

1. Run `terraform apply`.
1. From Cloud Shell, change the working directory to the `terraform` directory that you used to provision
    the resources for the second worker.
1. Initialize the following Terraform variables for the second worker:

    ```hcl
    distributed_tff_example_deploy_ingress_gateway = true
    distributed_tff_example_configuration          = {
        "fltenant1": {
            emnist_partition_file_name = "emnist_part_2.sqlite"
        }
    }
    ```

1. Run `terraform apply`.
1. Wait for the workers Deployments and Services to be ready.
1. From Cloud Shell, change the working directory to the `terraform` directory that you used to provision
    the resources for the second worker.
1. Initialize the following Terraform variables for the coordinator:

    ```hcl
    distributed_tff_example_configuration          = {
        "fltenant1": {
            is_coordinator = true
            worker_1_address = "<WORKER_1_SERVICE_IP_ADDRESS>"
            worker_2_address = "<WORKER_2_SERVICE_IP_ADDRESS>"
        }
    }
    ```

    Where:

    - `<WORKER_1_SERVICE_IP_ADDRESS>` is the IP address of the load balancer
        that exposes the first worker workloads.
    - `<WORKER_2_SERVICE_IP_ADDRESS>` is the IP address of the load balancer
        that exposes the second worker workloads.

1. Run `terraform apply`.
