---
name: setup-minio
description: Setup and configure MinIO (S3 compatible storage) for local development and Kubernetes. Use when the user asks to set up MinIO, configure S3 storage, or troubleshoot MinIO connection issues.
---

# Setup MinIO

## Quick Start

1. Start MinIO using Docker Compose:
   ```bash
   docker compose up -d s3 s3-init
   ```
2. Verify MinIO is running at http://localhost:9001 (Console) or http://localhost:9000 (API).

## Configuration

### Local Development (application-dev.yaml)
Ensure the following properties are set in your application configuration:

```yaml
aws:
  s3:
    bucket: decade-bucket
    access:
      id: decadedecade
      secret: decadedecade
    endpoint: http://localhost:9000
```

### Bucket Initialization
Buckets can be automatically created via an initialization script (e.g., `init-minio.sh`) run by an `s3-init` service in `docker-compose.yaml`.

## Implementation Guide

### Injecting S3 Client
Inject the `S3Client` (configured via Spring Cloud AWS or a custom bean) into your service:

```java
@Service
public class DocumentService {
    private final S3Client s3Client;
    private final String bucketName;

    public DocumentService(S3Client s3Client, @Value("${aws.s3.bucket}") String bucketName) {
        this.s3Client = s3Client;
        this.bucketName = bucketName;
    }
}
```

## Kubernetes Setup

MinIO can be deployed to Kubernetes using the official Helm chart.

### 1. Add Helm Repository
```bash
helm repo add minio https://charts.min.io/
helm repo update
```

### 2. Configuration (`k8s/infra/values.yaml`)
Reference the infrastructure configuration for MinIO settings:

```yaml
minio:
  mode: standalone
  replicas: 1
  existingSecret: "minio-secrets"
  buckets:
    - name: decade-bucket
      policy: download
      purge: false
```

### 3. Deploy Infrastructure
```bash
helm install infra ./k8s/infra -f ./k8s/infra/values-local.yaml
```

## Testing with MinIO

### 1. Testcontainers Integration
Use `MinIOContainer` from Testcontainers for integration testing.

```java
@Bean
MinIOContainer minioContainer() {
    return new MinIOContainer("minio/minio:RELEASE.2023-09-04T19-57-37Z")
        .withExposedPorts(9000)
        .withEnv("MINIO_ROOT_USER", "decadedecade")
        .withEnv("MINIO_ROOT_PASSWORD", "decadedecade");
}
```

###  dynamic Property Registration
Register properties dynamically so the application connects to the Testcontainers instance:

```java
@Bean
DynamicPropertyRegistrar awsProperties(MinIOContainer minio) {
    return registry -> {
        registry.add("aws.s3.endpoint", minio::getS3URL);
        registry.add("aws.s3.bucket", () -> "test-bucket");
        registry.add("aws.s3.access.id", minio::getUserName);
        registry.add("aws.s3.access.secret", minio::getPassword);
    };
}
```

## Common Operations

### Manual Bucket Creation
```bash
docker exec -it <minio-container-id> mc mb /data/new-bucket
```

### Accessing Console
Login to http://localhost:9001 with default credentials:
- **Username:** decadedecade
- **Password:** decadedecade
