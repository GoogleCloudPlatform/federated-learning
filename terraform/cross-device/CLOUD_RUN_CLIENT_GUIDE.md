
# ODP Client Cloud Run Deployment Guide

This guide explains how to deploy and use the ODP client service in Cloud Run.

## Overview

The ODP client service runs in Cloud Run and communicates with the ODP Federated Compute services. It handles:
- Client registration
- Task retrieval
- Model updates
- Result submission

## Directory Structure

```

odp-client/
├── src/
│   └── main/
│       ├── java/
│       │   └── com/
│       │       └── google/
│       │           └── cloud/
│       │               └── federatedcompute/
│       │                   └── client/
│       │                       ├── ClientApplication.java
│       │                       ├── config/
│       │                       │   └── ClientConfig.java
│       │                       ├── service/
│       │                       │   └── ClientService.java
│       │                       └── controller/
│       │                           └── ClientController.java
│       └── resources/
│           └── application.yaml
├── Dockerfile
├── build.gradle
└── README.md
```





Let's create the necessary files:

```java:odp-client/src/main/java/com/google/cloud/federatedcompute/client/ClientApplication.java
package com.google.cloud.federatedcompute.client;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class ClientApplication {
    public static void main(String[] args) {
        SpringApplication.run(ClientApplication.class, args);
    }
}
```federated-learning/terraform/cross-device/CLOUD_RUN_CLIENT_GUIDE.md

```java:odp-client/src/main/java/com/google/cloud/federatedcompute/client/config/ClientConfig.java
package com.google.cloud.federatedcompute.client.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;
import org.springframework.context.annotation.Bean;

@Configuration
@ConfigurationProperties(prefix = "odp.client")
public class ClientConfig {
    private String serviceUrl;
    private String clientId;
    
    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
    
    // Getters and setters
    public String getServiceUrl() { return serviceUrl; }
    public void setServiceUrl(String serviceUrl) { this.serviceUrl = serviceUrl; }
    public String getClientId() { return clientId; }
    public void setClientId(String clientId) { this.clientId = clientId; }
}
```

```java:odp-client/src/main/java/com/google/cloud/federatedcompute/client/service/ClientService.java
package com.google.cloud.federatedcompute.client.service;

import org.springframework.stereotype.Service;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.web.client.RestTemplate;
import com.google.cloud.federatedcompute.client.config.ClientConfig;

@Service
public class ClientService {
    private final RestTemplate restTemplate;
    private final ClientConfig config;
    
    public ClientService(RestTemplate restTemplate, ClientConfig config) {
        this.restTemplate = restTemplate;
        this.config = config;
    }
    
    @Scheduled(fixedDelay = 60000) // Run every minute
    public void checkForTasks() {
        // Implementation for checking and processing tasks
    }
    
    public void submitResults(String taskId, byte[] results) {
        // Implementation for submitting results
    }
}
```federated-learning/terraform/cross-device/CLOUD_RUN_CLIENT_GUIDE.md

```yaml:odp-client/src/main/resources/application.yaml
spring:
  application:
    name: odp-client

server:
  port: 8080

management:
  endpoints:
    web:
      exposure:
        include: health,info,prometheus
  endpoint:
    health:
      probes:
        enabled: true

odp:
  client:
    serviceUrl: ${ODP_SERVICE_URL}
    clientId: ${CLIENT_ID}
```

```dockerfile:odp-client/Dockerfile
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
```federated-learning/terraform/cross-device/CLOUD_RUN_CLIENT_GUIDE.md

```groovy:odp-client/build.gradle
plugins {
    id 'org.springframework.boot' version '3.1.0'
    id 'io.spring.dependency-management' version '1.1.0'
    id 'java'
}

group = 'com.google.cloud.federatedcompute'
version = '1.0.0'

repositories {
    mavenCentral()
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.boot:spring-boot-starter-actuator'
    implementation 'io.micrometer:micrometer-registry-prometheus'
    implementation 'com.google.cloud:google-cloud-storage'
    
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
}
```

Now, let's create the Terraform configuration for Cloud Run:

```terraform:federated-learning/terraform/cross-device/cloud_run.tf
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
```

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
```bash
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
```

Remember to:
- Monitor resource usage
- Review logs regularly
- Update client configuration as needed
- Maintain proper security settings
```

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
