# Blueprint: Preparing a GKE cluster for apps distributed by a third party

This repository contains a blueprint that creates and secures a
[Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/docs/concepts/kubernetes-engine-overview)
(GKE) cluster that is ready to host custom apps distributed by a third party.
For more information about the architecture of this blueprint, refer to
[Preparing a GKE cluster for third-party tenants](https://cloud.google.com/architecture/preparing-gke-cluster-apps-distributed-third-party).

This blueprint uses a GKE cluster as the compute infrastructure to host
containerized apps distributed by a third party. These apps are considered as
untrusuted or semi-trusted workloads within the cluster. Therefore, the cluster
is configured according to security best practices to isolate and constrain the
workloads from other workloads and from the cluster control plane. The blueprint
uses [Anthos](https://cloud.google.com/anthos) features to automate and optimise
the configuration and security of the cluster.

This blueprint provisions cloud resources on Google Cloud. After the initial provisioning,
you can extended the infrastructure to [Anthos clusters running on premises or on other public clouds](https://cloud.google.com/anthos/clusters/docs/multi-cloud).

## Getting started

To deploy this blueprint you need:

- A [Google Cloud project](https://cloud.google.com/docs/overview#projects) with billing enabled
- An account with the [Project Owner role](https://cloud.google.com/iam/docs/understanding-roles#resource-manager-roles) on the project

You create the infastructure using Terraform. The blueprint uses a local [Terraform backend](https://www.terraform.io/docs/language/settings/backends/configuration.html),
but we recommend to configure a [remote backend](https://www.terraform.io/language/settings/backends/configuration#backend-types)
for anything other than experimentation.

## Understanding the repository structure

This repository has the following key directories:

- [terraform](terraform): contains the Terraform code used to create the project-level infrastructure and resources, for example a GKE cluster, VPC network, firewall rules etc. It also installs Anthos components into the cluster
- [configsync](configsync): contains the cluster-level resources and configurations that are applied to your GKE cluster.
- [tenant-config-pkg](tenant-config-pkg): a [kpt](https://kpt.dev/?id=overview) package that you can use as a template to configure new tenants in the GKE cluster.

## Architecture

The blueprint uses a [multi-tenant](https://cloud.google.com/kubernetes-engine/docs/concepts/multitenancy-overview) architecture.

The workloads provided by third parties are treated as a tenant within the cluster. These tenant workloads are grouped in dedicated namespaces, and isolated on dedicated cluster nodes.
This way, you can apply security controls and policies to the nodes and namespace that host the tenant workloads.

### Infrastructure

The following diagram describes the infrastructure created by the blueprint
![alt_text](./assets/infra.png "Infrastructure overview")

The infrastructure provisioned by this blueprint includes:

- A [VPC network](https://cloud.google.com/vpc/docs/vpc) and subnet.
- A [private GKE cluster](https://cloud.google.com/kubernetes-engine/docs/concepts/private-cluster-concept). The blueprint helps you create GKE clusters that implement recommended security settings, such as those described in the [GKE hardening guide](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster). For example, the blueprint helps you:
  - Limit exposure of your cluster nodes and control plane to the internet by creating a private GKE cluster with [authorised networks](https://cloud.google.com/kubernetes-engine/docs/concepts/private-cluster-concept#overview).
  - Use shielded nodes that use a hardened node image with the containerd runtime.
  - Harden isolation of tenant workloads using [GKE Sandbox](https://cloud.google.com/kubernetes-engine/docs/concepts/sandbox-pods).
  - Enable [Dataplane V2](https://cloud.google.com/kubernetes-engine/docs/concepts/dataplane-v2) for optimised Kubernetes networking.
  - [Encrypt cluster secrets](https://cloud.google.com/kubernetes-engine/docs/how-to/encrypting-secrets) at the application layer.
- Two GKE [node pools](https://cloud.google.com/kubernetes-engine/docs/concepts/node-pools).
  - You create a dedicated node pool to exclusively host tenant apps and resources. The nodes have taints to ensure that only tenant workloads
  are scheduled onto the tenant nodes.
  - Other cluster resources are hosted in the main node pool.
- [VPC Firewall rules](https://cloud.google.com/vpc/docs/firewalls)
  - Baseline rules that apply to all nodes in the cluster.
  - Additional rules that apply only to the nodes in the tenant node pool (targeted using the node Service Account below). These firewall rules limit egress from the tenant nodes.
- [Cloud NAT](https://cloud.google.com/nat/docs/overview) to allow egress to the internet
- [Cloud DNS](https://cloud.google.com/dns/docs/overview) rules configured to enable [Private Google Access](https://cloud.google.com/vpc/docs/private-google-access) such that apps within the cluster can access Google APIs without traversing the internet
- [Service Accounts](https://cloud.google.com/iam/docs/understanding-service-accounts) used by the cluster.
  - A dedicated Service Account used by the nodes in the tenant node pool
  - A dedicated Service Account for use by tenant apps (via Workload Identity, discussed later).
- Support for using [Google Groups for Kubernetes RBAC](https://cloud.google.com/kubernetes-engine/docs/how-to/google-groups-rbac).

### Applications

The following diagram describes the apps and resources within the GKE cluster
![alt_text](./assets/apps.png "Cluster resources and applications")

The cluster includes:

- [Config Sync](https://cloud.google.com/anthos-config-management/docs/config-sync-overview), which keeps cluster configuration in sync with config defined in a Git repository.
  - The config defined by the blueprint includes namespaces, service accounts, network policies, Policy Controller policies and Istio resources that are applied to the cluster.
  - See the [configsync](configsync) dir for the full set of resources applied to the cluster
- [Policy Controller](https://cloud.google.com/anthos-config-management/docs/concepts/policy-controller) enforces policies ('constraints') for your clusters. These policies act as 'guardrails' and prevent any changes to your cluster that violate security, operational, or compliance controls.
  - Example policies enforced by the blueprint include:
    - Selected constraints [similar to PodSecurityPolicy](https://cloud.google.com/anthos-config-management/docs/how-to/using-constraints-to-enforce-pod-security)
    - Selected constraints from the [template library](https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library), including:
      - Prevent creation of external services (Ingress, NodePort/LoadBalancer services)
      - Allow pods to pull container images only from a named set of repositories
  - See the resources in the [configsync/policycontroller](configsync/policycontroller) directory for details of the constraints applied by this blueprint.
- [Anthos Service Mesh](https://cloud.google.com/service-mesh/docs/overview) (ASM) is powered by Istio and enables managed, observable, and secure communication across your services. The blueprint includes service mesh configuration that is applied to the cluster using Config Sync. The following points describe how this blueprint configures the service mesh.
  - The root istio namespace (istio-system) is configured with
    - PeerAuthentication resource to allow only STRICT mTLS communications between services in the mesh
    - AuthorizationPolicies that:
      - by default deny all communication between services in the mesh,
      - allow communication to a set of known external hosts (such as example.com)
    - Egress Gateway that acts a forward-proxy at the edge of the mesh
    - VirtualService and DestinationRule resources that route traffic from sidecar proxies through the egress gateway to external destinations.
  - The tenant namespace is configured for automatic sidecar proxy injection, see next section.
  - Note that the mesh does not include an Ingress Gateway
  - See the [servicemesh](configsync/servicemesh) dir for the cluster-level mesh config

The blueprint configures a dedicated namespace for tenant apps and resources:

- The tenant namespace is part of the service mesh. Pods in the namespace receive sidecar proxy containers. The namespace-level mesh resources include:
  - Sidecar resource that allows egress only to known hosts (outboundTrafficPolicy: REGISTRY_ONLY)
  - AuthorizationPolicy that defines the allowed communication paths within the namespace. The blueprint only allows requests that originate from within the same namespace. This
  policy is added to the root policy in the istio-system namespace
- The tenant namespace has [network policies](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy) to limit traffic to and from pods in the namespace. For example, the network policy:
  - By default, denies all ingress and egress traffic to/from the pods. This acts as baseline 'deny all' rule,
  - Allows traffic between pods in the namespace
  - Allows egress to required cluster resources like kube-dns, service mesh control plane and the GKE metadata server
  - Allows egress to Google APIs (via Private Google Access)
- The pods in the tenant namespace are hosted exclusively on nodes in the dedicated tenant node pool.
  - Any pod deployed to the tenant workspace automatically receives a toleration and nodeAffinity to ensure that it is scheudled only a tenant node
  - The toleration and nodeAffinity are automatically applied using [Policy Controller mutations](https://cloud.google.com/anthos-config-management/docs/how-to/mutation)
- The apps in the tenant namespace use a dedicated Kubernetes service account that is linked to a Google Cloud service account using [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity). This way you can grant appropriate IAM roles to interact with any required Google APIs.
- The blueprint includes a [sample RBAC ClusterRole](configsync/rbac.yaml) that grants users permissions to interact with limited resource types. The tenant namespace includes a [sample RoleBinding](tenant-config-pkg/rbac.yaml) that grants the role to an example user.
  - For example, different teams might be responsible for managing apps within each tenant namespace
  - Users and teams managing tenant apps should not have permissions to change cluster configuration or modify service mesh resources

## Deploy the blueprint

1. Open [Cloud Shell](https://cloud.google.com/shell)
1. Clone this repository
1. Change into the directory that contains the Terraform code:

  ```sh
  cd [REPOSITORY]/terraform
  ```

  Where `[REPOSITORY]` is the path to the directory where you cloned this repository.

1. Set a Terraform environment variable for your project ID in the `terraform.tfvars` file by setting the value of the `project_id` variable.
1. Initialize Terraform:

  ```sh
  terraform init
  ```

1. Review the proposed changes, and apply them:

  ```sh
  terraform apply
  ```

  This may take about 15 minutes to complete

### Add another tenant

This blueprint dynamically provisions a runtime environment for each tenant you
configure.

To add another tenant:

1. Add its name to the list of tenants to configure using the `tenant_names` variable.
1. Follow the steps to [Deploy the blueprint](#deploy-the-blueprint) again.

## Test

For more details about manual tests you can perform to validate this setup,
see the [testing directory](testing).
