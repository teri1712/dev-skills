---
name: infra-setup-observability
description: Set up Observability (Prometheus, Grafana, Loki, Tempo) for the project, covering Docker Compose, Helm (Kubernetes), Spring Boot binding, and Logback configuration. Use when adding metrics, tracing, or logging integration.
---

# Infra Setup: Observability

## Quick start

### 1. Update `compose.yaml`
Add observability services:
```yaml
services:
  prometheus:
    image: prom/prometheus:v2.51.0
    ports: ["9090:9090"]
    volumes: ["./prometheus.yml:/etc/prometheus/prometheus.yml"]
  loki:
    image: grafana/loki:3.0.0
    ports: ["3100:3100"]
  tempo:
    image: grafana/tempo:2.5.0
    ports: ["3200:3200", "4317:4317", "4318:4318"]
    volumes: ["./tempo.yml:/etc/tempo.yaml"]
  grafana:
    image: grafana/grafana:11.0.0
    ports: ["3000:3000"]
    environment:
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: admin
    depends_on: [prometheus, loki, tempo]
```

### 2. Spring Boot Binding & Logback (Mandatory)

**`src/main/resources/application.yml`**:
```yaml
management:
  tracing:
    sampling:
      probability: 1.0
  observations:
    annotations:
      enabled: true
  metrics:
    tags:
      application: ${spring.application.name}

**`src/main/resources/application-dev.yml`**:
```yaml
loki:
  url: http://localhost:3100/loki/api/v1/push

management:
  otlp:
    tracing:
      endpoint: http://localhost:4318/v1/traces
```

**`src/main/resources/logback-spring.xml`**:
You MUST configure the Loki appender as follows:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration debug="true">
    <include resource="org/springframework/boot/logging/logback/defaults.xml"/>
    
    <springProperty scope="context" name="APP_NAME" source="spring.application.name" defaultValue="chatapp"/>
    <springProperty scope="context" name="LOKI_URL" source="loki.url" defaultValue="http://localhost:3100/loki/api/v1/push"/>

    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%clr(%d{yyyy-MM-dd HH:mm:ss}){faint} %clr([%thread]){faint} %clr(%-5level) %clr(%logger{36}){cyan} %clr(traceId=%X{traceId} spanId=%X{spanId}){faint} - %msg%n${LOG_EXCEPTION_CONVERSION_WORD:-%wEx}</pattern>
        </encoder>
    </appender>

    <appender name="LOKI" class="com.github.loki4j.logback.Loki4jAppender">
        <http>
            <url>${LOKI_URL}</url>
        </http>
        <maxRetries>5</maxRetries>
        <minRetryBackoffMs>1000</minRetryBackoffMs>
        <maxRetryBackoffMs>60000</maxRetryBackoffMs>
        <format>
            <label>
                <pattern>app=${APP_NAME},host=${HOSTNAME}</pattern>
            </label>
            <message>
                <pattern>traceId=%X{traceId} spanId=%X{spanId} %d{HH:mm:ss} %-5level %logger{36} - %msg%n</pattern>
            </message>
        </format>
    </appender>

    <root level="INFO">
        <appender-ref ref="CONSOLE"/>
        <appender-ref ref="LOKI"/>
    </root>
</configuration>
```

### 3. Kubernetes (Helm) & Release
Update `k8s/observability/Chart.yaml` dependencies:
```yaml
dependencies:
  - name: prometheus
    version: 29.8.0
    repository: https://prometheus-community.github.io/helm-charts
  - name: loki
    version: 16.1.0
    repository: https://grafana-community.github.io/helm-charts
  - name: tempo
    version: 2.1.2
    repository: https://grafana-community.github.io/helm-charts
  - name: grafana
    version: 12.3.2
    repository: https://grafana-community.github.io/helm-charts
```

**Local Configuration (`k8s/observability/values-local.yaml`):**
```yaml
# Local scaling for Kind cluster
prometheus:
  server:
    persistentVolume:
      size: 2Gi
    resources:
      limits: { cpu: 500m, memory: 512Mi }
      requests: { cpu: 250m, memory: 512Mi }

grafana:
  initChownData: { enabled: false }
  persistence: { size: 1Gi }
  resources:
    limits: { cpu: 500m, memory: 256Mi }
    requests: { cpu: 200m, memory: 128Mi }

loki:
  loki:
    server:
      http_server_write_timeout: 1m
  singleBinary:
    persistence: { size: 2Gi }
    resources:
      limits: { cpu: 2000m, memory: 2Gi }
      requests: { cpu: 1000m, memory: 256Mi }

tempo:
  tempo:
    persistence: { size: 2Gi }
    resources:
      limits: { cpu: 1000m, memory: 1Gi }
      requests: { cpu: 500m, memory: 256Mi }
```

**Production Configuration (`k8s/observability/values-prod.yaml`):**
```yaml
# GKE Production Profile
prometheus:
  server:
    persistentVolume:
      storageClass: "premium-rwo"
      size: 10Gi

grafana:
  persistence:
    storageClassName: "premium-rwo"
    size: 5Gi

loki:
  singleBinary:
    persistence:
      storageClass: "premium-rwo"
      size: 10Gi

tempo:
  tempo:
    persistence:
      storageClass: "premium-rwo"
      size: 10Gi
```

**Deployment / Release:**
1. Run `helm dependency update k8s/observability`.
2. Ensure `chatapp-secrets` exists.
3. Deploy Local: `helm upgrade --install observability k8s/observability -f k8s/observability/values-local.yaml`
4. Deploy Prod: `helm upgrade --install observability k8s/observability -f k8s/observability/values-prod.yaml`

## Advanced features

- **Tracing:** Probability set to 1.0 by default.
- **Log Aggregation:** Loki integration via `Loki4jAppender` in Logback.
