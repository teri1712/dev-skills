---
name: setup-minio
description: Setup and configure MinIO (S3 compatible storage) for local development and Kubernetes. Use when the user asks to set up MinIO, configure S3 storage, or troubleshoot MinIO connection issues.
---

# Setup MinIO

## Quick Start (Docker Compose)

Add the following services to your `compose.yaml` to start LocalStack (configured for S3) or MinIO:

```yaml
services:
  s3:
    image: localstack/localstack:2.3
    ports:
      - "4566:4566"
    environment:
      SERVICES: s3
      AWS_DEFAULT_REGION: ap-southeast-1
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./compose/s3:/etc/localstack/init/ready.d
```

### Bucket Initialization Script
Create `compose/s3/01-init-s3.sh` (ensure it's executable: `chmod +x`):

```bash
#!/bin/bash
set -e
awslocal s3 mb s3://decade-bucket

# Optional: Set public read policy
awslocal s3api put-bucket-policy \
  --bucket decade-bucket \
  --policy '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::decade-bucket/*"
      }
    ]
  }'
```

## Configuration

### application-dev.yaml
```yaml
aws:
  s3:
    region: ap-southeast-1
    bucket: decade-bucket
    endpoint: http://localhost:4566
    public-endpoint: http://localhost:4566
    access:
      id: test
      secret: test
```

## Java Implementation

### 1. Dependency
Add to `pom.xml`:
```xml
<dependency>
    <groupId>software.amazon.awssdk</groupId>
    <artifactId>s3</artifactId>
</dependency>
```

### 2. S3 Configuration Class
```java
@Configuration
public class S3Config {
    @Value("${aws.s3.endpoint}") private String endpoint;
    @Value("${aws.s3.region}") private String region;
    @Value("${aws.s3.access.id}") private String accessId;
    @Value("${aws.s3.access.secret}") private String accessSecret;

    @Bean
    public S3Client s3Client() {
        return S3Client.builder()
            .endpointOverride(URI.create(endpoint))
            .region(Region.of(region))
            .serviceConfiguration(S3Configuration.builder()
                .pathStyleAccessEnabled(true) // Required for local/minio
                .build())
            .credentialsProvider(StaticCredentialsProvider.create(
                AwsBasicCredentials.create(accessId, accessSecret)))
            .build();
    }
}
```

## Kubernetes Setup (Helm)

### Configuration (`k8s/infra/values.yaml`)
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

## Testing (Testcontainers)

```java
@Bean
MinIOContainer minioContainer() {
    return new MinIOContainer("minio/minio:RELEASE.2023-09-04T19-57-37Z")
        .withExposedPorts(9000);
}

@Bean
DynamicPropertyRegistrar awsProperties(MinIOContainer minio) {
    return registry -> {
        registry.add("aws.s3.endpoint", minio::getS3URL);
        registry.add("aws.s3.access.id", minio::getUserName);
        registry.add("aws.s3.access.secret", minio::getPassword);
    };
}
```
