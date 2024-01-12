# Cross-device Federated Learning

This module is an example of an end to end demo for cross-device Federated Learning. This example deploys 6 different workloads:
- `aggregator`: this is a job that reads device gradients and calculates aggregated result with Differential Privacy
- `collector`: this is a job that runs periodically to query active task and encrypted gradients, resulting in deciding when to kick off aggregating
- `modelupdater`: this is a job that listens to events and publishes results so that device can download
- `task-assignment`: this is a front end service that distributes training tasks to devices
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

### Containers running in different namespaces, in the same GKE cluster

1. Provision infrastructure by following the instructions in the [main README](../../README.md).
1. From Cloud Shell, change the working directory to the `terraform` directory.
1. Initialize the following Terraform variables:

    ```hcl
        enable_confidential_nodes         = true
        cluster_tenant_pool_machine_type  = "n2d-standard-4"
        cluster_default_pool_machine_type = "n2d-standard-4"
        cross_device                      = true
    ```

1. Run `terraform apply`, and wait for Terraform to complete the provisioning process.
