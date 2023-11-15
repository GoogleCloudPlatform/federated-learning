# Cross-device Federated Learning

This module is an example of an end to end demo for cross-device Federated Learning

## Infrastructure
It creates:
- A spanner instance for storing the status of training
- Pubsub topics that act as buses for messages between microservices
- Buckets for storing the trained models