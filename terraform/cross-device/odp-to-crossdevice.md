# How to Deploy ODP Services to Cross-Device Infrastructure

This guide explains how to build and deploy ODP Federated Compute services to the cross-device infrastructure.

## Prerequisites

- Google Cloud SDK installed and configured
- Access to the GCP project
- Docker installed
- JDK 17 or later installed
- Terraform installed
- Git access to both repositories:
  - federated-learning
  - odp-federatedcompute

## 1. Deploy Base Infrastructure

1. Initialize the cross-device infrastructure:
```bash
cd federated-learning/terraform/cross-device

# Initialize Terraform
terraform init

# Create or update terraform.tfvars
cat > terraform.tfvars << EOF
enable_confidential_nodes         = true
cluster_tenant_pool_machine_type  = "n2d-standard-4"
cluster_default_pool_machine_type = "n2d-standard-4"
cross_device                      = true
EOF

# Apply Terraform configuration
terraform apply
```

## 2. Build ODP Services

1. Set up environment variables:
```bash
export PROJECT_ID=$(gcloud config get-value project)
export VERSION=$(date +%Y%m%d-%H%M%S)
```

2. Navigate to the ODP services directory:
```bash
cd /path/to/odp-federatedcompute/federatedcompute
```

3. Build the services:
```bash
# Make build script executable
chmod +x build-services.sh

# Build and push images
./build-services.sh
```

## 3. Deploy ODP Services

1. Apply ODP service Terraform configuration:
```bash
cd /path/to/federated-learning/terraform/cross-device

# Apply Terraform changes
terraform apply
```

2. Deploy services to the cluster:
```bash
cd /path/to/odp-federatedcompute/federatedcompute

# Make deploy script executable
chmod +x deploy-services.sh

# Deploy services
./deploy-services.sh
```

## 4. Verify Deployment

1. Get cluster credentials:
```bash
CLUSTER_NAME=$(terraform output -raw cluster_name)
LOCATION=$(terraform output -raw cluster_location)
gcloud container clusters get-credentials $CLUSTER_NAME --location $LOCATION
```

2. Check deployment status:
```bash
# Check pods
kubectl get pods -n odp-federated

# Check services
kubectl get services -n odp-federated

# Check deployments
kubectl get deployments -n odp-federated
```

## 5. Monitor Services

1. View service logs:
```bash
# View logs for a specific service
kubectl logs -l app=odp-federated,service=<service-name> -n odp-federated

# Stream logs
kubectl logs -f -l app=odp-federated -n odp-federated
```

2. Check service health:
```bash
# Get service endpoints
kubectl get endpoints -n odp-federated

# Check service health
for svc in $(kubectl get services -n odp-federated -o name); do
  kubectl get --raw "/api/v1/namespaces/odp-federated/$svc/proxy/actuator/health"
done
```

## Troubleshooting

### Common Issues

1. **Image Pull Errors**
```bash
# Check image pull status
kubectl describe pod -n odp-federated <pod-name>

# Verify image exists
gcloud container images list --repository=gcr.io/${PROJECT_ID}/federated-compute
```

2. **Service Account Issues**
```bash
# Check service account binding
kubectl get serviceaccount -n odp-federated

# Verify IAM roles
gcloud projects get-iam-policy ${PROJECT_ID} \
  --flatten="bindings[].members" \
  --format='table(bindings.role,bindings.members)' \
  --filter="bindings.members:odp-*"
```

3. **Network Issues**
```bash
# Check network policies
kubectl get networkpolicies -n odp-federated

# Test service connectivity
kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot -n odp-federated -- /bin/bash
```

## Cleanup

To remove ODP services:

```bash
# Delete namespace and all resources
kubectl delete namespace odp-federated

# Or remove specific services
kubectl delete deployment,service,networkpolicy -l app=odp-federated -n odp-federated
```

## Additional Notes

1. **Security Considerations**
   - All services run as non-root user
   - Network policies restrict communication
   - Service mesh provides mTLS
   - Confidential computing enabled if configured

2. **Resource Management**
   - Services configured with resource limits
   - Java memory settings optimized for containers
   - Horizontal scaling available if needed

3. **Monitoring**
   - Spring Boot Actuator endpoints enabled
   - Prometheus metrics available
   - Health check endpoints configured
   - Logging configured for Cloud Operations

4. **Maintenance**
   - Regular updates recommended
   - Monitor resource usage
   - Check service health regularly
   - Review security configurations

## References

- [Cross-Device Infrastructure Documentation](../../README.md)
- [ODP Services Documentation](../../../odp-federatedcompute/README.md)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)

#### Services
| Service Name | Port | Protocol | Purpose |
|--------------|------|----------|----------|
| aggregator | 8080 | HTTP/gRPC | Aggregates model updates |
| collector | 8080 | HTTP/gRPC | Collects training results |
| model-updater | 8080 | HTTP/gRPC | Updates model versions |
| task-assignment | 8080 | HTTP/gRPC | Assigns tasks to clients |
| task-management | 8080 | HTTP/gRPC | Manages task lifecycle |
| task-scheduler | 8080 | HTTP/gRPC | Schedules training tasks |

#### Resource Requirements
| Service | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---------|-------------|------------|----------------|--------------|
| All Services | 500m | 2 | 2Gi | 3Gi |

### GCP Resources

#### Service Accounts
| Service | Account ID | Roles |
|---------|------------|-------|
| aggregator | odp-aggregator-sa | pubsub.publisher, spanner.databaseUser |
| collector | odp-collector-sa | pubsub.publisher, spanner.databaseUser |
| model-updater | odp-model-updater-sa | storage.objectViewer, pubsub.publisher |
| task-assignment | odp-task-assignment-sa | spanner.databaseUser |
| task-management | odp-task-management-sa | pubsub.publisher, spanner.databaseUser |
| task-scheduler | odp-task-scheduler-sa | pubsub.publisher, spanner.databaseUser |

#### Cloud Spanner
- Instance: fcp_task_spanner_instance
- Database: fcp_task_spanner_database

#### Pub/Sub Topics
| Topic | Purpose | Publishers | Subscribers |
|-------|----------|------------|-------------|
| aggregator_topic | Model updates | aggregator | model-updater |
| task_topic | Task assignments | task-scheduler | task-assignment |

## Service Configuration

### Environment Variables
| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| SPRING_PROFILES_ACTIVE | Spring profile | Yes | prod |
| PUBSUB_PROJECT_ID | GCP project ID | Yes | - |
| SPANNER_INSTANCE | Spanner instance | Yes | - |
| SPANNER_DATABASE | Spanner database | Yes | - |
| JAVA_OPTS | JVM options | No | -XX:+UseG1GC -XX:MaxGCPauseMillis=100 |

### Health Checks

### Monitoring
```yaml
Metrics:
  Path: /actuator/prometheus
  Port: 8080
  Scrape: true
```

## Network Configuration

### Network Policies
```yaml
Ingress:
  Ports:
    - 8080/TCP
  From:
    - app: odp-federated
Egress:
  To:
    - All pods in namespace
```

### Service Mesh
```yaml
Authorization Policy:
  Principals: cluster.local/ns/odp-federated/sa/*
  Action: ALLOW
```

## Build Configuration

### Docker Images
```yaml
Base Image: eclipse-temurin:17-jre-jammy
Registry: gcr.io/${PROJECT_ID}/federated-compute
Tags:
  - latest
  - ${VERSION}
```

### Build Arguments
| Argument | Description | Default |
|----------|-------------|---------|
| SERVICE_NAME | Service identifier | Required |
| VERSION | Image version | latest |

## Deployment Configuration

### Terraform Variables
| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| odp_image_version | Service image version | string | latest |
| odp_enable_monitoring | Enable monitoring | bool | true |
| odp_java_memory_limit | Java memory limit | string | 3Gi |
| odp_java_memory_request | Java memory request | string | 2Gi |

### Required Permissions
1. GKE Cluster Access
   - roles/container.developer
   - roles/container.viewer

2. GCP Service Usage
   - roles/pubsub.publisher
   - roles/spanner.databaseUser
   - roles/storage.objectViewer

## Security Configuration

### Pod Security
```yaml
SecurityContext:
  runAsNonRoot: true
  runAsUser: 10000
  runAsGroup: 10000
```

### Network Security
1. Service Mesh
   - mTLS enabled
   - Authorization policies
   - Traffic encryption

2. Network Policies
   - Pod-to-pod communication
   - External access control

## Monitoring and Logging

### Metrics
1. JVM Metrics
   - Memory usage
   - Garbage collection
   - Thread counts

2. Application Metrics
   - Request rates
   - Response times
   - Error rates

### Logging
```yaml
Format: JSON
Fields:
  - timestamp
  - service
  - level
  - message
  - trace_id
```

## Maintenance Procedures

### Version Updates
1. Build new images:
```bash
./build-services.sh
```

2. Update deployments:
```bash
./deploy-services.sh
```

### Scaling
```yaml
Horizontal Pod Autoscaling:
  minReplicas: 1
  maxReplicas: 5
  targetCPUUtilizationPercentage: 80
```

### Backup and Recovery
1. Spanner Backups
   - Daily automated backups
   - Retention: 7 days

2. Configuration Backups
   - Version controlled
   - Stored in Git repository

## Troubleshooting

### Common Issues
1. Pod Startup Failures
   - Check logs: `kubectl logs -n odp-federated <pod>`
   - Check events: `kubectl get events -n odp-federated`

2. Service Communication
   - Verify network policies
   - Check service mesh configuration
   - Test connectivity between services

3. Resource Issues
   - Monitor resource usage
   - Check pod metrics
   - Review JVM memory settings

## API Documentation

### Service Endpoints
| Service | Endpoint | Method | Purpose |
|---------|----------|--------|----------|
| All | /actuator/health | GET | Health check |
| All | /actuator/prometheus | GET | Metrics |
| All | /actuator/info | GET | Service info |

## Dependencies

### Required Services
1. Google Cloud Platform
   - Cloud Spanner
   - Pub/Sub
   - Cloud Storage
   - Container Registry

2. Kubernetes
   - GKE 1.24+
   - Istio Service Mesh
   - Prometheus

### Software Versions
- Java: 17
- Spring Boot: 3.1.0
- GKE: 1.24+
- Istio: 1.18+

This guide provides comprehensive instructions for deploying ODP services to the cross-device infrastructure. Adjust paths and configurations according to your specific setup.
