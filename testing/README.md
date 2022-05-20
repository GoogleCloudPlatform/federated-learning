# Testing

This guide provides step-by-step instructions to manually test and verify cluster configuration.

## Setup

- Set local variables, replacing with your own values where appropriate

  ```sh
  PROJECT=your_project
  CLUSTER=fedlearn
  ZONE=europe-west1-b
  TENANT=fltenant1
  ASM_REVISION=asm-110
  ```

### Get cluster credentials

- Get cluster credentials:
`gcloud container clusters get-credentials $CLUSTER --zone $ZONE --project $PROJECT`

### Deploy an example tenant service

- deploy a simple 'hello world' service to the tenant namespace
`kubectl apply -f ./testing/hello-service.yaml -n $TENANT`

- The tenant namespace is enabled for Istio injection. Verify the pods have an istio-proxy container
`kubectl -n $TENANT get pods -l app=hello -o jsonpath='{.items..spec.containers[*].name}'`

- Verify that the tenant pods are all hosted on nodes in the dedicated tenant node-pool
`kubectl get pods -o wide -n $TENANT`

## Verify firewall rules

- For convenience, create a local variable that describes an output format for firewall rules list. This defines the set of columns
to display when listing firewall rules

  ```sh
  FWTABLE="table(
    name,
    network,
    sourceRanges.list():label=[SRC_RANGES],
    destinationRanges.list():label=[DEST_RANGES],
    allowed[].map().firewall_rule().list():label=ALLOW,
    denied[].map().firewall_rule().list():label=DENY,
    sourceTags.list():label=[SRC_TAGS],
    targetTags.list():label=[TARGET_TAGS],
    targetServiceAccounts.list():label=[TARGET_SA]
  )"
  ```

### Test firewall rules

- Print the nodes in the cluster. The node names include the name of the node-pool. Note that the nodes
do not have External IP addresses as this is a private cluster.
`kubectl get nodes -o wide`

- GKE nodes receieve a label with the node-pool name. Print the nodes in the dedicated tenant node-pool.
`kubectl get nodes -l cloud.google.com/gke-nodepool=$TENANT-pool`

- Show the Service Account attached to the cluster nodes. The tenant pool nodes use a dedicated Service Account
`gcloud compute instances list --format="table(name, serviceAccounts.email:label=SERVICEACCOUNT)" --filter="name:$CLUSTER"`

- Print any firewall rules with 'ssh' in the name, excluding the default network. You see that there is an explicit 'allow ssh' firewall rule that targets any node with the 'gke-flsilo' tag
`gcloud compute firewall-rules list  --filter "name~ssh AND -network=default" --format $FWTABLE`

- SSH into one of the tenant nodes. You tunnel through IAP as the nodes do not have external IP addresses.
`gcloud compute ssh --tunnel-through-iap $(kubectl get nodes -l cloud.google.com/gke-nodepool=$TENANT-pool -o jsonpath='{.items[0].metadata.name}')`

- Make a request to a website. The request times out.
`curl -i -m 10 example.com`

- Exit the ssh session on the cluster node
`exit`

- Print any EGRESS firewall rules. You see that there is a 'deny all' firewall rule for nodes that use the tenant service account. Therefore, this firewall rule applies only to the nodes in the tenant node pool. This rule blocked your previous curl request from the tenant node.
`gcloud compute firewall-rules list  --filter "direction=EGRESS" --format $FWTABLE`

## Verify network policy

### Deploy a test

- deploy test pod to the default namespace. You use this test pod to perform requests against the service in the tenant namespace.
`kubectl apply -f ./testing/test-pod.yaml -n default`

- Verify that the pods are hosted on nodes in the main node-pool (not in the tenant node-pool)
`kubectl -n default get pods -o wide`

- wait for the pod to be ready
`kubectl wait --for=condition=Ready pod -l app=test -n default`

- The default namespace is not enabled for Istio injection. Verify the pod does not have an istio-proxy container
`kubectl -n default get pods -l app=test -o jsonpath='{.items..spec.containers[*].name}'`

### Test the interation

- From the test pod in the default namespace, call the service in the tenant namespace

  ```sh
  kubectl -n default exec -it -c test \
    $(kubectl -n default get pod -l app=test -o jsonpath={.items..metadata.name}) \
    -- curl hello.$TENANT.svc.cluster.local
  ```

- The call hangs. Terminate the request with CTRL-C, or wait for the request to timeout.

- The network policy in the tenant namespace does not allow requests (ingress) from the default namespace.

## Verify Anthos Service Mesh auth

Run some tests to verify auth behaviour of your Anthos Service Mesh

## Verify failed PeerAuthentication

### Deploy a test pod that does not have an Istio proxy

- create a new namespace named 'test'
`kubectl create namespace test`

- deploy test pod to the test namespace. You use this test pod to perform requests against the service in the tenant namespace.
`kubectl apply -f ./testing/test-pod.yaml -n test`

- Verify that the pods are hosted on nodes in the main node-pool (not in the tenant node-pool)
`kubectl -n test get pods -o wide`

- wait for the pod to be ready
`kubectl wait --for=condition=Ready pod -l app=test -n test`

- The test namespace is not enabled for Istio injection. Verify the pod does not have an istio-proxy container
`kubectl -n test get pods -l app=test -o jsonpath='{.items..spec.containers[*].name}'`

### Test the interation (no Istio proxy)

- From the test pod in the test namespace, call the service in the tenant namespace

  ```sh
  kubectl -n test exec -it -c test \
    $(kubectl -n test get pod -l app=test -o jsonpath={.items..metadata.name}) \
    -- curl hello.$TENANT.svc.cluster.local
  ```

- You see a "Connection reset by peer" failure.
- The istio-proxy in the hello pod rejects the request because the tenant namespace has STRICT PeerAuthentication policy. Only authenticated requests are allowed. As the test pod is not part of the mesh (it doesn't have istio-proxy container), the request fails authentication.
- **NOTE** that the network policy in the tenant namespace allows requests from the test namespace. Therefore the request is allowed by Kubernetes, and the request then progresses to the tenant service. This network policy is
included explicitly for testing purposes. You should remove this policy in a production cluster.

### Verify failed AuthorizationPolicy

#### Deploy a test pod that does receive an Istio proxy

- enable the test namespace for automatic Istio proxy injection
`kubectl label namespace test "istio.io/rev=$ASM_REVISION"`

- restart the pods in the test deployment. The new pods receive istio-proxy containers
`kubectl rollout restart deployment test -n test`

- wait for the pod to be ready
`kubectl wait --for=condition=Ready pod -l app=test -n test`

- Verify the test pod now has an istio-proxy sidecar container
`kubectl -n test get pods -l app=test -o jsonpath='{.items..spec.containers[*].name}'`

#### Test the interaction

- From the test pod in the testing namespace, call the service in the tenant namespace

  ```sh
  kubectl -n test exec -it -c test \
    $(kubectl -n test get pod -l app=test -o jsonpath={.items..metadata.name}) \
    -- curl hello.$TENANT.svc.cluster.local
  ```

- You see an "RBAC: access denied" failure.
- This request came from a pod within the mesh, an mTLS connection between the two istio-proxies was established, and the request was successfully authenticated. However, the request was rejected due to AuthorizationPolicy applied to the tenant namespace. The AuthorizationPolicy only allows requests that originated from the same namespace.

### Verify success

#### Deploy a test pod to the tenant namespace

- deploy a test pod to the tenant namespace. This namespace is enabled for istio injection
`kubectl apply -f ./testing/test-pod.yaml -n $TENANT`

- wait for the pod to be ready
`kubectl wait --for=condition=Ready pod -l app=test -n $TENANT`

- Verify the pod has an istio-proxy sidecar container
`kubectl -n $TENANT get pods -l app=test -o jsonpath='{.items..spec.containers[*].name}'`

#### Test the interaction (tenant namespace)

- From the test pod in the tenant namespace, call the service in the tenant namespace

  ```sh
  kubectl -n $TENANT exec -it -c test \
    $(kubectl -n $TENANT get pod -l app=test -o jsonpath={.items..metadata.name}) \
    -- curl hello.$TENANT.svc.cluster.local
  ```

- The request succeeds! You see some HTML content returned by the hello service.
- The network policy in the tenant namespace allows requests from within the namespace. As the request originated from the mesh, the tenant service istio-proxy correctly authenticated the request. As the request originated from
within the tenant namespace, the request also passed the authorization checks.

## Verify Anthos Service Mesh egress

Run some tests to verify egress behaviour of your Anthos Service Mesh.
**NOTE** that the network policy in the tenant namespace allows egress to the istio-system namespace.

### Verify failed unknown destination host

The mesh is configured to only allow requests to known services (via the REGISTRY_ONLY outboundTrafficPolicy on the Sidecar resource).

- deploy a test pod to the tenant namespace. This namespace is enabled for istio injection
`kubectl apply -f ./testing/test-pod.yaml -n $TENANT`

- Verify the pod does have an istio-proxy sidecar container
`kubectl -n $TENANT get pods -l app=test -o jsonpath='{.items..spec.containers[*].name}'`

- Verify that the tenant namepace has REGISTRY_ONLY outboundTrafficPolicy. Therefore egress from the mesh is only allowed to hosts that exist in the registry
`kubectl get sidecar -n $TENANT -o jsonpath='{.items[0].spec.outboundTrafficPolicy}'`

- List the ServiceEntries (TODO: use istioctl). You see that there is a ServiceEntry that configures some external domains (example.com etc)
`kubectl get ServiceEntry -A`

- From the test pod in the tenant namespace, make a request to 'example.org'. Note that this domain is not configured in the ServiceEntries.

  ```sh
  kubectl -n $TENANT exec -it -c test \
    $(kubectl -n $TENANT get pod -l app=test -o jsonpath={.items..metadata.name}) \
    -- curl -i example.org
  ```

- You see a 502 error. There is no ServiceEntry for this host (it is not in the service registry) so the mesh does not allow the egress

### Verify successful request to known host

- From the test pod in the tenant namespace, make a request to 'example.com'.

  ```sh
  kubectl -n $TENANT exec -it -c test \
    $(kubectl -n $TENANT get pod -l app=test -o jsonpath={.items..metadata.name}) \
    -- curl -i example.com
  ```

- You see a successful 200 response, and the HTML of the page. There is a ServiceEntry for example.com, so the mesh forwards the request

## Verify interaction with Google APIs

- The tenant namespace has a Kubernetes service account resource called 'ksa'. Note that the service account has the 'iam.gke.io/gcp-service-account'
annotation. This is used by Workload Identity to map the Kubernetes service account to a corresponding IAM service account.
`kubectl describe serviceaccount ksa -n $TENANT`

- Update the test deployment in the tenant namespace, adding the 'ksa' service account. The test pods will now use the service account.
`kubectl patch deployment test -n $TENANT --patch-file ./testing/patch-serviceaccount.yaml`

- Verify that the test pod has the 'ksa' service account.
`kubectl -n $TENANT get pods -l app=test -o jsonpath='{.items..spec.serviceAccount}'`

- wait for the pod to be ready
`kubectl wait --for=condition=Ready pod -l app=test -n $TENANT`

- From the test pod in the tenant namespace, list the Cloud Storage buckets in the project

  ```sh
  kubectl -n $TENANT exec -it -c test \
    $(kubectl -n $TENANT get pod -l app=test -o jsonpath={.items..metadata.name}) \
    -- gsutil ls -p $PROJECT
  ```

- You see a 403 (Permission Denied) error. The pod does not have permissions to list storage buckets.
The cluster is configured for Workload Identity. The 'ksa' Kubernetes Service Account in the tenant namespace
is mapped to a named IAM Service Account dedicated to the tenant.

- List the IAM permissions for the service account used by tenant apps. The sevice account does not have any
Cloud Storage permissions

  ```sh
  gcloud projects get-iam-policy $PROJECT \
    --flatten="bindings[].members" \
    --filter "bindings.members:$CLUSTER-$TENANT-apps-sa@$PROJECT.iam.gserviceaccount.com"
  ```

- Grant the Viewer IAM role to the Service Account used by apps in the tenant namespace. Note this grants View permissions to
all resources in the project. The role is removed in a subsequent step.

  ```sh
  gcloud projects add-iam-policy-binding $PROJECT \
    --member=serviceAccount:$CLUSTER-$TENANT-apps-sa@$PROJECT.iam.gserviceaccount.com \
    --role=roles/viewer
  ```

- Try to list the Cloud Storage buckets in the project again

  ```sh
  kubectl -n $TENANT exec -it -c test \
    $(kubectl -n $TENANT get pod -l app=test -o jsonpath={.items..metadata.name}) \
    -- gsutil ls -p $PROJECT
  ```

- This time the request succeeds, and you see the default Cloud Storage buckets

- To clean up, remove the IAM role

  ```sh
  gcloud projects remove-iam-policy-binding $PROJECT \
    --member=serviceAccount:$CLUSTER-$TENANT-apps-sa@$PROJECT.iam.gserviceaccount.com \
    --role=roles/viewer
  ```

## Add another tenant

Out-of-the-box the blueprint is configured with a single tenant. You can add more tenants by updating the config. Each tenant is configured in the same way.

### Create new infra for the new tenant

First, create the project-level infra and resources for the new tenant.

- Add another element to the `tenant_names` var in `terraform.tfvars`. For example:
`tenant_names=["fltenant1", "tenant2"]`

- Apply the terraform again. A new node pool, service accounts, firewall rules etc will be created for tenant2. This can take a few minutes due to the nodepool creation
`terraform apply -auto-approve`

- Verfiy that a new node pool has been added for tenant2
`kubectl get nodes -l cloud.google.com/gke-nodepool=tenant2-pool`

- And also new service accounts for tenant2
`gcloud iam service-accounts list`

### Create cluster configuration for the new tenant

Now you need to create the cluster-level resources for the new tenant (tenant namespace, network policy, Istio policies etc).
You use the [tenant-config-pkg](tenant-config-pkg) kpt package to configure the tenant resources.
The tenant config is automatically applied to the cluster using Config Sync.

- Change into the directory where tenant configs are stored

```sh
cd configsync/tenants
```

- Instantiate the tenant-config-pkg package into a new tenant2 dir. You reference the package from your local repository
(NOTE in most cases the package would be defined in a remote repository)

```sh
REPO=$(git rev-parse --show-toplevel)
kpt pkg get $REPO.git/tenant-config-pkg tenant2
```

- Confgure the package, updating default values with tenant-specific values. This updates the namespace to be 'tenant2' etc.

  ```sh
  kpt fn eval --image gcr.io/kpt-fn/apply-setters:v0.2 -- \
    tenant-name=tenant2 \
    gcp-service-account=$CLUSTER-tenant2-apps-sa@$PROJECT.iam.gserviceaccount.com \
    tenant-developer=someuser@email
  ```

- Commit and push the changes to your git repository

```sh
git commit -m "added tenant2"
git push
```

- Anthos Config Management will sync the new config to the cluster.

- Wait 30 seconds and then check the namespaces; you should see a new 'tenant2' namespace
`kubectl get ns`
