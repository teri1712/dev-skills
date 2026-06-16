---
name: setup-minio
description: Setup and configure MinIO (S3 compatible storage) for local development and Kubernetes. Use when the user asks to set up MinIO, configure S3 storage, or troubleshoot MinIO connection issues.
---

# Setup MinIO

## Quick Start (Docker Compose)

Add the following services to your `compose.yaml` to start MinIO:

```yaml
services:
  s3:
    image: minio/minio:RELEASE.2024-01-16T16-07-38Z
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      MINIO_ROOT_USER: decadedecade
      MINIO_ROOT_PASSWORD: decadedecade
    command: server /data --console-address ":9001"

  s3-init:
    image: minio/mc
    depends_on:
      - s3
    entrypoint: >
      /bin/sh -c "
      /usr/bin/mc alias set mys3 http://s3:9000 decadedecade decadedecade;
      /usr/bin/mc mb mys3/decade-bucket;
      /usr/bin/mc anonymous set download mys3/decade-bucket;
      exit 0;
      "
```

## Configuration

### application-dev.yaml
```yaml
aws:
  s3:
    region: us-east-1 # MinIO default or any valid region
    bucket: decade-bucket
    endpoint: http://localhost:9000
    public-endpoint: http://localhost:9000
    access:
      id: decadedecade
      secret: decadedecade
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
                .pathStyleAccessEnabled(true) // Required for MinIO
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
