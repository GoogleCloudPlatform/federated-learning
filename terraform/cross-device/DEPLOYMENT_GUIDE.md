# Cross-Device Platform Deployment Guide

This guide provides step-by-step instructions for deploying the cross-device platform and ODP services.

## Prerequisites

- Google Cloud SDK installed and configured
- Terraform installed (version 1.0+)
- Docker installed
- JDK 17 installed
- Git access to both repositories
- `kubectl` installed

## 1. Initial Setup

# Set environment variables

export PROJECT_ID=$(gcloud config get-value project)
export REGISTRY_PATH="gcr.io/${PROJECT_ID}/federated-compute" 
export VERSION=$(date +%Y%m%d-%H%M%S)

# Configure Docker for GCR

gcloud auth configure-docker


# Enable required GCP APIs

gcloud services enable \
container.googleapis.com \
spanner.googleapis.com \
pubsub.googleapis.com \
cloudkms.googleapis.com \
artifactregistry.googleapis.com

## 2. Deploy Cross-Device Infrastructure

```bash
# Navigate to Terraform directory
cd /path/to/federated-learning/terraform/cross-device

# Create terraform.tfvars
cat > terraform.tfvars << EOF
project_id                        = "${PROJECT_ID}"
region                           = "us-central1"
enable_confidential_nodes         = true
cluster_tenant_pool_machine_type  = "n2d-standard-4"
cluster_default_pool_machine_type = "n2d-standard-4"
cross_device                     = true
EOF

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -out=tfplan

# Apply configuration
terraform apply tfplan

# Get cluster credentials
export CLUSTER_NAME=$(terraform output -raw cluster_name)
export LOCATION=$(terraform output -raw cluster_location)
gcloud container clusters get-credentials $CLUSTER_NAME --location $LOCATION
```

## 3. Build ODP Service Images

```bash
# Navigate to ODP services directory
cd /path/to/odp-federatedcompute/shuffler/services

# Create base Dockerfile
cat > Dockerfile.base << 'EOF'
FROM eclipse-temurin:17-jdk-jammy AS builder

WORKDIR /build
COPY . .
RUN ./gradlew clean bootJar

FROM eclipse-temurin:17-jre-jammy

WORKDIR /app
COPY --from=builder /build/build/libs/*.jar app.jar

RUN groupadd -r javauser && useradd -r -g javauser -u 10000 javauser
RUN chown -R javauser:javauser /app
USER javauser

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF

# Create build script
cat > build-services.sh << 'EOF'
#!/bin/bash
set -e

PROJECT_ID=$(gcloud config get-value project)
REGISTRY_PATH="gcr.io/${PROJECT_ID}/federated-compute"
VERSION=${VERSION:-latest}

SERVICES=(
    "aggregator"
    "collector"
    "model-updater"
    "task-assignment"
    "task-management"
    "task-scheduler"
)

for SERVICE in "${SERVICES[@]}"; do
    echo "Building ${SERVICE}..."
    
    # Build service
    ./gradlew :${SERVICE}:clean :${SERVICE}:bootJar
    
    # Build Docker image
    docker build \
        -t "${REGISTRY_PATH}/${SERVICE}:${VERSION}" \
        -f ${SERVICE}/Dockerfile \
        --build-arg SERVICE_NAME=${SERVICE} \
        .
    
    # Push image
    docker push "${REGISTRY_PATH}/${SERVICE}:${VERSION}"
    docker tag "${REGISTRY_PATH}/${SERVICE}:${VERSION}" "${REGISTRY_PATH}/${SERVICE}:latest"
    docker push "${REGISTRY_PATH}/${SERVICE}:latest"
done
EOF

# Make script executable
chmod +x build-services.sh

# Build and push images
./build-services.sh
```

## 4. Deploy ODP Services

```bash
# Navigate back to Terraform directory
cd /path/to/federated-learning/terraform/cross-device

# Create ODP services configuration
cat > odp_services.tf << EOF
# ... (Copy content from previous odp_services.tf example)
EOF

# Apply ODP services configuration
terraform apply -target=module.odp_services

# Verify deployments
kubectl get pods -n odp-federated
kubectl get services -n odp-federated
```

## 5. Configure Service Mesh

```bash
# Apply Istio configuration
kubectl apply -f - << EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: odp-services-policy
  namespace: odp-federated
spec:
  selector:
    matchLabels:
      app: odp-federated
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/odp-federated/sa/*"]
EOF
```

## 6. Configure Monitoring

```bash
# Create monitoring namespace
kubectl create namespace monitoring

# Deploy Prometheus
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/bundle.yaml

# Configure service monitors
kubectl apply -f - << EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: odp-services
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: odp-federated
  endpoints:
  - port: http
    path: /actuator/prometheus
EOF
```

## 7. Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n odp-federated

# Check services
kubectl get services -n odp-federated

# Check service health
for svc in $(kubectl get services -n odp-federated -o name); do
  kubectl get --raw "/api/v1/namespaces/odp-federated/$svc/proxy/actuator/health"
done

# Check logs
kubectl logs -l app=odp-federated -n odp-federated
```

## 8. Test Services

```bash
# Port forward to test locally
kubectl port-forward svc/aggregator 8080:8080 -n odp-federated

# In another terminal, test health endpoint
curl http://localhost:8080/actuator/health
```

## 9. Setup Config Sync (Optional)

```bash
# Enable Config Sync
gcloud container clusters update $CLUSTER_NAME \
    --project=$PROJECT_ID \
    --location=$LOCATION \
    --enable-config-sync

# Configure Git repository
kubectl apply -f - << EOF
apiVersion: configsync.gke.io/v1beta1
kind: RootSync
metadata:
  name: root-sync
  namespace: config-management-system
spec:
  sourceFormat: unstructured
  git:
    repo: https://github.com/your-org/federated-learning
    branch: main
    dir: config-sync
    auth: token
    secretRef:
      name: git-creds
EOF
```

## Troubleshooting

### Common Issues

1. **Image Pull Errors**
```bash
# Check image exists
gcloud container images list --repository=$REGISTRY_PATH

# Check pod events
kubectl describe pod <pod-name> -n odp-federated
```

2. **Service Account Issues**
```bash
# Verify service account
kubectl get serviceaccount -n odp-federated

# Check IAM bindings
gcloud projects get-iam-policy $PROJECT_ID \
    --flatten="bindings[].members" \
    --format='table(bindings.role,bindings.members)' \
    --filter="bindings.members:odp-*"
```

3. **Network Issues**
```bash
# Test connectivity
kubectl run tmp-shell --rm -i --tty \
    --image nicolaka/netshoot \
    -n odp-federated -- /bin/bash
```

## Cleanup

```bash
# Delete ODP services
kubectl delete namespace odp-federated

# Delete monitoring
kubectl delete namespace monitoring

# Destroy infrastructure
terraform destroy
```

## Next Steps

1. Set up CI/CD pipelines
2. Configure alerts
3. Set up backup procedures
4. Document service APIs
5. Configure auto-scaling

Remember to:
- Keep track of deployed versions
- Monitor resource usage
- Review security configurations
- Maintain backup procedures
```

This guide provides comprehensive instructions for deploying the cross-device platform and ODP services. Adjust paths, configurations, and steps according to your specific requirements and environment.
