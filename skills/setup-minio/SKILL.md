---
name: setup-minio
description: Setup and configure MinIO (S3 compatible storage) for the Nexa project. Use when the user asks to set up MinIO, configure S3 storage, or troubleshoot MinIO connection issues.
---

# Setup MinIO

## Quick Start

1. Start MinIO using Docker Compose:
   ```bash
   docker compose up -d s3 s3-init
   ```
2. Verify MinIO is running at http://localhost:9001 (Console) or http://localhost:9000 (API).

## Configuration

### Local Development (`application-dev.yaml`)
Ensure the following properties are set in `src/main/resources/application-dev.yaml`:

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
Buckets are automatically created by the `s3-init` service in `compose.yaml` which runs `compose/s3/init-minio.sh`.
Default bucket: `decade-bucket`.

## Testing

MinIO is integrated into tests via `src/test/java/com/decade/nexa/common/Containers.java`.

### Test Setup
Tests use `MinIOContainer` and dynamic property registration:
- `aws.s3.endpoint`: Dynamically assigned by Testcontainers.
- `aws.s3.bucket`: `test-bucket`.
- `aws.s3.access.id`: `decadedecade`.
- `aws.s3.access.secret`: `decadedecade`.

To use MinIO in a test, use the `@ComponentTest` annotation and include `MinIOContainer` in your test configuration if not already present in the shared `Containers` class.

## Common Operations

### Manual Bucket Creation
If you need to create a bucket manually:
```bash
docker exec -it nexa-s3-1 mc mb /data/new-bucket
```

### Accessing Console
Login to http://localhost:9001 with:
- **Username:** `decadedecade`
- **Password:** `decadedecade`
