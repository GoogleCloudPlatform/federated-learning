# Federated Learning for image classification

In this tutorial, we use the classic MNIST training example to introduce the
Federated Learning (FL) API layer of TFF, `tff.learning` - a set of
higher-level interfaces that can be used to perform common types of federated
learning tasks, such as federated training, against user-supplied models
implemented in TensorFlow.

This tutorial, and the Federated Learning API, are intended primarily for users
who want to plug their own TensorFlow models into TFF, treating the latter
mostly as a black box.

This example builds on top of the infrastructure that the
[blueprint provides](../../../../README.md), and follows the best practices the
blueprint establishes.

## Prerequisites

- A POSIX-compliant shell
- Git (tested with version 2.41)
- Docker (tested with version 20.10.21)

## How to run

### Containers running in different namespaces, in the same GKE cluster

1. Provision infrastructure by following the instructions in the [main README](../../../../README.md).
1. From Cloud Shell, change the working directory to the `terraform` directory.
1. Run `terraform apply`.
1. Wait for GKE to report the coordinator and the workers as `Ready` in the
    [GKE Workloads dashboard](https://cloud.google.com/kubernetes-engine/docs/concepts/dashboards#workloads).

## Expected output

## Development environment

Prerequisities:

- The ones listed [above](#prerequisites)
- Docker Compose (tested with version 1.29.2)

To run this example, build the container images and run containers:

```sh
docker compose \
    --file compose.yaml \
    up \
    --abort-on-container-exit \
    --build
```
