# ODP Client Cloud Run Deployment Guide

This guide explains how to deploy and use the ODP client service in Cloud Run.

## Overview

The ODP client service runs in Cloud Run and communicates with the ODP Federated Compute services. It handles:

- Client registration
- Task retrieval
- Model updates
- Result submission

## Directory Structure

Now, let's create the Terraform configuration for Cloud Run:

````terraform:federated-learning/terraform/cross-device/cloud_run.tf
# Cloud Run configuration for ODP client

resource "google_cloud_run_service" "odp_client" {
  name     = "odp-client"
  location = var.region

  template {
    spec {
      containers {
        image = "${var.registry_path}/odp-client:latest"

        env {
          name  = "ODP_SERVICE_URL"
          value = "https://${kubernetes_service.odp_services["task-assignment"].status.0.load_balancer.0.ingress.0.ip}"
        }

        env {
          name  = "CLIENT_ID"
          value = "cloud-run-client-${random_id.client_suffix.hex}"
        }

        resources {
          limits = {
            cpu    = "1000m"
            memory = "2Gi"
          }
        }
      }

      service_account_name = google_service_account.odp_client.email
    }
  }
}

resource "random_id" "client_suffix" {
  byte_length = 4
}

resource "google_service_account" "odp_client" {
  account_id   = "odp-client-sa"
  display_name = "ODP Client Service Account"
}

resource "google_project_iam_member" "odp_client_roles" {
  for_each = toset([
    "roles/storage.objectViewer",
    "roles/pubsub.publisher"
  ])

  project = data.google_project.project.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.odp_client.email}"
}
```federated-learning/terraform/cross-device/CLOUD_RUN_CLIENT_GUIDE.md

## Deployment Steps

1. **Build the Client**:
```bash
# Navigate to client directory
cd odp-client

# Build and push Docker image
PROJECT_ID=$(gcloud config get-value project)
IMAGE_PATH="gcr.io/${PROJECT_ID}/federated-compute/odp-client"

# Build image
docker build -t ${IMAGE_PATH}:latest .

# Push image
docker push ${IMAGE_PATH}:latest
````

2. **Deploy to Cloud Run**:

```bash:federated-learning/terraform/cross-device/CLOUD_RUN_CLIENT_GUIDE.md
# Apply Terraform configuration
cd ../federated-learning/terraform/cross-device
terraform apply -target=google_cloud_run_service.odp_client
```

3. **Verify Deployment**:

```bash
# Get Cloud Run URL
gcloud run services describe odp-client \
    --platform managed \
    --region $(terraform output -raw region) \
    --format 'value(status.url)'

# Check service health
curl $(gcloud run services describe odp-client \
    --platform managed \
    --region $(terraform output -raw region) \
    --format 'value(status.url)')/actuator/health
```

## Usage

The client service will automatically:

1. Register with the ODP services
2. Poll for available tasks
3. Process tasks when available
4. Submit results back to the platform

### Monitoring

1. **View Logs**:

```bash
gcloud logging read "resource.type=cloud_run_revision AND \
    resource.labels.service_name=odp-client" --limit 50
```

2. **Check Metrics**:

```bash
# View Cloud Run metrics
gcloud monitoring metrics list \
    --filter="metric.type=run.googleapis.com/request_count"
```

### Troubleshooting

1. **Service Issues**:

````bash
# Check service status
gcloud run services describe odp-client \
    --platform managed \
    --region $(terraform output -raw region)

# View recent logs
gcloud logging read "resource.type=cloud_run_revision AND \
    resource.labels.service_name=odp-client AND severity>=ERROR" \
    --limit 10
```federated-learning/terraform/cross-device/CLOUD_RUN_CLIENT_GUIDE.md

2. **Connectivity Issues**:
```bash
# Test connectivity to ODP services
curl -v ${ODP_SERVICE_URL}/actuator/health
````

Remember to:

- Monitor resource usage
- Review logs regularly
- Update client configuration as needed
- Maintain proper security settings

This setup provides a Cloud Run-based client for the ODP Federated Compute platform. The client automatically processes tasks and integrates with the main platform services.

## Usage

The client service will automatically:

1. Register with the ODP services
2. Poll for available tasks
3. Process tasks when available
4. Submit results back to the platform

#### This client code provides:

Task polling and processing
Error handling and retries
Health checks and monitoring
Secure configuration
Logging and metrics
Docker containerization

#### Key features:

Automatic task polling
Retry mechanism for resilience
Health check endpoints
Prometheus metrics
Configurable parameters
Secure execution

##### Remember to:

Implement the task processing logic in TaskProcessor
Configure appropriate timeouts
Set up proper logging
Test thoroughly
Monitor performance

##### The client will automatically:
Register with the ODP services
Poll for available tasks
Process tasks when available
Submit results or report failures
Provide health and metrics endpoints

```

```
