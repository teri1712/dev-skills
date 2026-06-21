# Connecting Spring Boot to Elasticsearch (Nexa Project Pattern)

This reference outlines the configuration dependencies and application properties used in the Nexa project to connect Spring Boot to Elasticsearch.

## 1. Dependency Management (`pom.xml`)

The project uses both Spring Data Elasticsearch and Spring AI Vector Store starters:

```xml
<!-- Spring Data Elasticsearch -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-elasticsearch</artifactId>
</dependency>

<!-- Spring AI Vector Store (Elasticsearch) -->
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-starter-vector-store-elasticsearch</artifactId>
</dependency>
```

---

## 2. Spring Properties Configuration

The project maps connection configuration parameters conditionally via profiles.

### Development Configuration (`application-dev.yaml`)

```yaml
spring:
  elasticsearch:
    uris: http://localhost:9200
```

### Production Configuration (`application-prod.yaml`)

```yaml
spring:
  elasticsearch:
    uris: ${ELASTICSEARCH_URL}
    username: ${ELASTICSEARCH_USERNAME}
    password: ${ELASTICSEARCH_PASSWORD}
```

### Spring AI Vector Store Settings (`application.yaml`)

The vector store configuration is defined universally in `application.yaml`:

```yaml
spring:
  ai:
    vectorstore:
      elasticsearch:
        dimensions: 768
        index-name: nexa-documents
        initialize-schema: true
        similarity: cosine
        embedding-field-name: embedding
```

- **index-name**: The documents are written to the `nexa-documents` index.
- **initialize-schema**: Automatically creates/configures the index maps on application startup.
