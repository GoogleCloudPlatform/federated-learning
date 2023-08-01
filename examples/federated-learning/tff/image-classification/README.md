# Image classification tutorial example

In this directory, you can find an example of the
[Federated Learning for Image Classification](https://www.tensorflow.org/federated/tutorials/federated_learning_for_image_classification)
tutorial.

This example runs on a single host.

## Prerequisites

- Docker (tested with version 20.10.21)

## How to run

To run this example, do the following:

1. Build the container image:

    ```sh
    docker build -t tff-image-classification-example .
    ```

1. Run a container based on the continaer image:

    ```sh
    docker run --rm -it tff-image-classification-example
    ```
