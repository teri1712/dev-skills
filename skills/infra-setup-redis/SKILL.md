---
name: infra-setup-redis
description: Set up Redis for the project, covering Docker Compose, Helm (Kubernetes), and Spring Boot binding. Use when setting up Redis, adding caching, or configuring Redis-based session management.
---

# Infra Setup: Redis

## Quick start

### 1. Update `compose.yaml`
Add the redis service:
```yaml
services:
  redis:
    image: redis/redis-stack:latest
    ports:
      - "6379:6379"
      - "8001:8001"
    healthcheck:
      test: [ "CMD", "redis-cli", "ping" ]
      interval: 5s
      timeout: 3s
      retries: 20
      start_period: 5s
```

### 2. Spring Boot Binding (Mandatory)
Update the following properties:

**`src/main/resources/application.yml`**:
```yaml
spring:
  data:
    redis:
      timeout: 60000
      client-type: lettuce
```

**`src/main/resources/application-dev.yml`**:
```yaml
spring:
  data:
    redis:
      host: localhost
      port: 6379
```

**`src/main/resources/application-prod.yml`**:
```yaml
spring:
  data:
    redis:
      host: ${REDIS_HOST}
      password: ${REDIS_PASSWORD}
```

### 3. Kubernetes (Helm) & Release
Update `k8s/infra/Chart.yaml` dependencies:
```yaml
dependencies:
  - name: redis
    version: 25.5.3
    repository: https://charts.bitnami.com/bitnami
```

**Local Configuration (`k8s/infra/values-local.yaml`):**
```yaml
redis:
  master:
    persistence:
      enabled: false # Scale down for local Kind cluster
```

**Production Configuration (`k8s/infra/values-prod.yaml`):**
```yaml
redis:
  replica:
    replicaCount: 1
  master:
    persistence:
      storageClass: "premium-rwo"
      size: 8Gi
    resources:
      limits:
        cpu: 500m
        memory: 512Mi
      requests:
        cpu: 250m
        memory: 512Mi
```

**Deployment / Release:**
1. Run `helm dependency update k8s/infra`.
2. Ensure the secret `chatapp-secrets` exists.
3. Deploy Local: `helm upgrade --install infra k8s/infra -f k8s/infra/values-local.yaml`
4. Deploy Prod: `helm upgrade --install infra k8s/infra -f k8s/infra/values-prod.yaml`

## Advanced features

- **Redis Stack:** Includes RedisInsight on port 8001 in Compose. Useful for visual debugging of data structures.
- **Persistence:** Enabled by default in K8s via master persistence. Scale down to `persistence.enabled: false` for local Kind testing to save resources.
- **Testing (Testcontainers):** Use the following dependency for integration tests:
```xml
<dependency>
    <groupId>com.redis</groupId>
    <artifactId>testcontainers-redis</artifactId>
    <version>2.2.2</version>
    <scope>test</scope>
</dependency>
```
- **Performance:** Lettuce is used as the default non-blocking client. Connection pooling can be configured if high concurrency is required.
