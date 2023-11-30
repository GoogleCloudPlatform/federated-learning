# Cross-device Federated Learning

This module is an example of an end to end demo for cross-device Federated Learning. This example deploys 6 different workloads:
- `aggregator`: this is an offline job that reads device gradients and calculates aggregated result with DP
- `collector`: this is an offline job that runs periodically to query active task and encrypted gradients, resulting in deciding when to kick off aggregating
- `modelupdater`: this is an offline job that listens to events and publishes results so that device can download
- `task-assignment`: this is a front end service that distributes training tasks to devices
- `task-management`: this is an offline job that manages tasks
- `task-scheduler`: this is an offline job that either runs periodically or is triggered by some events

This example builds on top of the infrastructure that the
[blueprint provides](../../../../README.md), and follows the best practices the
blueprint establishes.

## Prerequisites

- A POSIX-compliant shell
- Git (tested with version 2.41)
- Docker (tested with version 20.10.21)

## Infrastructure

It creates:
- A spanner instance for storing the status of training
- Pubsub topics that act as buses for messages between microservices
- Buckets for storing the trained models

To deploy this solution, just set the `cross-device` flag to `true`.

To ensure end-to-end confidentiality, you need to enable confidential nodes.

However, it is also necessary to use VM families that support this feature, such as **N2D** or **C2D**.
When using confidential nodes, set `enable_confidential_nodes` to `true` and `cluster_tenant_pool_machine_type` to `n2d-standard-8`. In addition, in order to have the minimum number of replicas required during deployment, you need at least 4 nodes.

You will then deploy the cross-device workloads in a namespace. You will need to set the `tenant_namespace` variable with the name of the namespace in which you want to deploy the workloads.

### Containers running in different namespaces, in the same GKE cluster

1. Provision infrastructure by following the instructions in the [main README](../../../../README.md).
1. From Cloud Shell, change the working directory to the `terraform` directory.
1. Initialize the following Terraform variables:

    ```hcl
        enable_confidential_nodes         = true
        cluster_tenant_pool_machine_type  = "n2d-standard-4"
        cluster_default_pool_machine_type = "n2d-standard-4"
        cross-device                      = true
        tenant_namespace                  = "main"
    ```

1. Run `terraform apply`, and wait for Terraform to complete the provisioning process.
1. Open the [GKE Workloads Dashboard](https://cloud.google.com/kubernetes-engine/docs/concepts/dashboards#workloads)
    and wait for the workers Deployments and Services to be ready.
