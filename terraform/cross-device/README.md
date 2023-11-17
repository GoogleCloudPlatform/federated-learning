# Cross-device Federated Learning

This module is an example of an end to end demo for cross-device Federated Learning

## Infrastructure
It creates:
- A spanner instance for storing the status of training
- Pubsub topics that act as buses for messages between microservices
- Buckets for storing the trained models

To deploy this solution and ensure end-to-end confidentiality, you need to enable confidential nodes.
However, it is also necessary to use VM families that support this feature, such as **N2D** or **C2D**.
When using confidential nodes, set `enable_confidential_nodes` to `true` and `cluster_tenant_pool_machine_type` to `n2d-standard-8`. In addition, in order to have the minimum number of replicas required during deployment, you need at least 4 nodes and set `cluster_tenant_pool_min_nodes` to `4`.
