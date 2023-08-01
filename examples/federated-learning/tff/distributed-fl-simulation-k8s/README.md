# Image classification tutorial example

In this directory, you can find an example of the
[High-Performance Simulation with Kubernetes](https://www.tensorflow.org/federated/tutorials/high_performance_simulation_with_kubernetes)
tutorial.

This example runs on a single host.

## Prerequisites

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

TODO
