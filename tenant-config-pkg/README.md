# tenant-config-pkg

## Description

This [kpt](https://kpt.dev/) package contains resources that define baseline, common configuration
for a tenant within the untrusted workloads cluster. The package contains cluster resources such as:

- namespace, with a label for automatic service mesh proxy injection
- network policy
- service account, with a Workload Identity annotation
- service mesh resources, such as AuthorizationPolicy
- config for Policy Controller Mutuations that automatically apply labels/tolerations etc to Pods
in the tenant namespace

### Available setters

The pkg has placeholder values that you can replace with tenant-specific values, to configure the pkg
for that tenant. Available setters are:

- tenant-name: the name of the tenant, which is also used as the name of the namespace dedicated to
the tenant.
- gcp-service-account: the Service Account used by apps within the tenant namespace. Mapped to a Kubernetes
service account using Workload Identity
- tenant-developer: email address of user/group that operates the tenant apps within the tenant namespace.
Used to bind to a ClusterRole with limited permissions.
