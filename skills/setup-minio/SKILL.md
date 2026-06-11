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

### Local Development (application-dev.yaml)
Ensure the following properties are set in src/main/resources/application-dev.yaml:

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
Buckets are automatically created by the s3-init service in compose.yaml which runs compose/s3/init-minio.sh.
Default bucket: decade-bucket.

## Implementation Guide

### Injecting S3 Client
To use MinIO in your service, inject the S3Client (configured via Spring Cloud AWS or a custom bean):

```java
@Service
public class DocumentService {
    private final S3Client s3Client;
    private final String bucketName;

    public DocumentService(S3Client s3Client, @Value("${aws.s3.bucket}") String bucketName) {
        this.s3Client = s3Client;
        this.bucketName = bucketName;
    }
    // ... use s3Client.putObject, etc.
}
```

## Testing with MinIO

### 1. The @ComponentTest Annotation
The project uses a custom @ComponentTest annotation found in src/test/java/com/decade/nexa/common/ComponentTest.java. This annotation automatically imports Containers.class, which manages the MinIO lifecycle.

### 2. Automatic Lifecycle Management
In src/test/java/com/decade/nexa/common/Containers.java, the MinIOContainer is defined as a Bean. When you use @ComponentTest, Testcontainers starts MinIO and injects the dynamic properties:

```java
@Bean
MinIOContainer minioContainer() {
    return new MinIOContainer("minio/minio:RELEASE.2023-09-04T19-57-37Z")
        .withExposedPorts(9000)
        .withEnv("MINIO_ROOT_USER", "decadedecade")
        .withEnv("MINIO_ROOT_PASSWORD", "decadedecade");
}

@Bean
DynamicPropertyRegistrar awsProperties(MinIOContainer localStack) {
    return registry -> {
        registry.add("aws.s3.endpoint", localStack::getS3URL);
        registry.add("aws.s3.bucket", () -> "test-bucket");
        registry.add("aws.s3.access.id", localStack::getUserName);
        registry.add("aws.s3.access.secret", localStack::getPassword);
    };
}
```

### 3. Writing a Test
To write a test that requires MinIO, simply annotate your test class with @ComponentTest:

```java
@ComponentTest
class DocumentUploadIntegrationTest {

    @Autowired
    private S3Client s3Client;

    @Test
    void shouldUploadFileToMinio() {
        // The s3Client is already pointing to the Testcontainers MinIO instance
        // aws.s3.bucket is "test-bucket" by default in tests
    }
}
```

## Common Operations

### Manual Bucket Creation
If you need to create a bucket manually:
```bash
docker exec -it nexa-s3-1 mc mb /data/new-bucket
```

### Accessing Console
Login to http://localhost:9001 with:
- **Username:** decadedecade
- **Password:** decadedecade
