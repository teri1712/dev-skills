---
name: setup-s3-storage
description: Configure S3 storage for development (LocalStack) and production, including Spring Boot configuration, initialization scripts, and presigned URL support. Use when implementing file uploads, S3 bucket integration, or setting up LocalStack for local development.
---

# Setup S3 Storage

This skill provides instructions and templates for setting up S3-compatible storage using LocalStack for development and standard AWS S3 for production.

## Quick start

To set up S3 in a new project:
1. Add `software.amazon.awssdk:s3` dependency.
2. Add LocalStack to `compose.yaml`.
3. Create an initialization script in `compose/s3/01-init-s3.sh`.
4. Configure `S3Config.java` and `application.yml`.

## Workflows

### 1. Dev Environment (LocalStack)
Add the following to your `compose.yaml`:
```yaml
s3:
  image: localstack/localstack
  ports:
    - "4566:4566"
  environment:
    - SERVICES=s3
  volumes:
    - ./compose/s3:/etc/localstack/init/ready.d
```

### 2. Initialization Script
Create `compose/s3/01-init-s3.sh`:
```bash
#!/bin/bash
set -e
awslocal s3 mb s3://${BUCKET_NAME:-decade-bucket}
awslocal s3api put-bucket-policy --bucket ${BUCKET_NAME:-decade-bucket} --policy '{...}'
awslocal s3api put-bucket-cors --bucket ${BUCKET_NAME:-decade-bucket} --cors-configuration '{...}'
```

### 3. Spring Boot Configuration
Create `S3Config.java` to define `S3Client` and `S3Presigner` beans. Ensure `pathStyleAccessEnabled(true)` is set for LocalStack compatibility.

### 4. Application Properties
- **dev**: `aws.s3.endpoint: http://localhost:4566`
- **prod**: `aws.s3.endpoint: ${S3_ENDPOINT}` (or omit if using default AWS endpoints)

## Advanced Features
- **Presigned URLs**: Use `S3Presigner` to generate temporary upload/download links.
- **CORS**: Ensure `AllowedOrigins` includes your frontend domain.
- **Public Access**: Use bucket policies for public read access if needed.
