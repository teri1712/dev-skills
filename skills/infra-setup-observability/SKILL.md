---
name: infra-setup-observability
description: Set up Observability (Prometheus, Grafana, Loki, Tempo) for the project, covering Docker Compose, Helm (Kubernetes), Spring Boot binding, and Logback configuration. Use when adding metrics, tracing, or logging integration.
---

# Infra Setup: Observability

## Quick start

### 1. Create Configuration Files
Create `compose/prometheus.yml`:
```yaml
global:
  scrape_interval: 10s

scrape_configs:
  - job_name: "spring-boot-app"
    metrics_path: "/actuator/prometheus"
    static_configs:
      - targets: [ "host.docker.internal:8081" ]
```

Create `compose/tempo.yml`:
```yaml
server:
  http_listen_port: 3200

distributor:
  receivers:
    otlp:
      protocols:
        grpc:
        http:

storage:
  trace:
    backend: local
    local:
      path: /var/tempo/traces
    wal:
      path: /var/tempo/wal
```

### 2. Update `compose.yaml`
Add observability services:
```yaml
services:
  prometheus:
    image: prom/prometheus:v2.51.0
    ports: ["9090:9090"]
    volumes: ["./compose/prometheus.yml:/etc/prometheus/prometheus.yml"]
  loki:
    image: grafana/loki:3.0.0
    ports: ["3100:3100"]
  tempo:
    image: grafana/tempo:2.5.0
    ports: ["3200:3200", "4317:4317", "4318:4318"]
    volumes: ["./compose/tempo.yml:/etc/tempo.yaml"]
  grafana:
    image: grafana/grafana:11.0.0
    ports: ["3000:3000"]
    environment:
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: admin
    depends_on: [prometheus, loki, tempo]
```

### 3. Spring Boot Binding & Logback (Mandatory)

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

### 4. Kubernetes (Helm) & Release
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

**Base Configuration Blueprint (`k8s/observability/values.yaml`):**
```yaml
# Blueprint for Observability Stack
prometheus:
  prometheus-node-exporter:
    enabled: false
  alertmanager:
    enabled: false
  prometheus-pushgateway:
    enabled: false
  kube-state-metrics:
    enabled: false
  configmapReload:
    prometheus:
      enabled: false
  server:
    persistentVolume:
      enabled: true
      accessModes: [ "ReadWriteOnce" ]
      size: "" # Defined in profiles
    resources: { } # Defined in profiles

grafana:
  enabled: true
  admin:
    existingSecret: "chatapp-secrets"
    userKey: "admin-user"
    passwordKey: "admin-password"
  testFramework:
    enabled: false
  initChownData:
    enabled: false
  persistence:
    enabled: true
    size: "" # Defined in profiles
  resources: { } # Defined in profiles
  serviceMonitor:
    enabled: false
  grafana.ini:
    unified_alerting:
      enabled: false
    alerting:
      enabled: false
  additionalDataSources:
    - name: Prometheus
      type: prometheus
      url: http://observability-prometheus-server
      access: proxy
      isDefault: true
    - name: Loki
      type: loki
      url: http://observability-loki:3100
      access: proxy
    - name: Tempo
      type: tempo
      url: http://observability-tempo:3200
      access: proxy

loki:
  deploymentMode: Monolithic
  test:
    enabled: false
  lokiCanary:
    enabled: false
  gateway:
    enabled: false
  resultsCache:
    enabled: false
  chunksCache:
    enabled: false
  monitoring:
    serviceMonitor:
      enabled: false
    selfMonitoring:
      enabled: false
      grafanaAgent:
        install: false
  loki:
    auth_enabled: false
    useTestSchema: true
    commonConfig:
      replication_factor: 1
    storage:
      type: 'filesystem'
  singleBinary:
    replicas: 1
    persistence:
      enabled: true
      size: "" # Defined in profiles
    resources: { } # Defined in profiles
  read:
    replicas: 0
  write:
    replicas: 0
  backend:
    replicas: 0
  memcached:
    chunksCache:
      enabled: false
    resultsCache:
      enabled: false
  minio:
    enabled: false

tempo:
  tempo:
    persistence:
      enabled: true
      size: "" # Defined in profiles
    resources: { } # Defined in profiles
    receivers:
      otlp:
        protocols:
          http:
            endpoint: "0.0.0.0:4318"
          grpc:
            endpoint: "0.0.0.0:4317"
  serviceMonitor:
    enabled: false
  gateway:
    enabled: false
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

**GKE Production Configuration (`k8s/observability/values-gke.yaml`):**
```yaml
# GKE Production Profile - Observability
# Economical settings to prioritize resources for App and Infra services
prometheus:
  server:
    persistentVolume:
      storageClass: "standard-rwo"
      size: 10Gi
    resources:
      limits:
        cpu: 1000m
        memory: 1Gi
      requests:
        cpu: 500m
        memory: 1Gi

grafana:
  persistence:
    size: 1Gi
  resources:
    limits:
      cpu: 250m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 512Mi

loki:
  loki:
    resources:
      limits:
        cpu: 500m
        memory: 1Gi
      requests:
        cpu: 500m
        memory: 512Mi
  singleBinary:
    persistence:
      storageClass: "standard-rwo"
      size: 8Gi

tempo:
  persistence:
    storageClass: "standard-rwo"
    size: 8Gi
  tempo:
    resources:
      limits:
        cpu: 500m
        memory: 1Gi
      requests:
        cpu: 500m
        memory: 512Mi
```

**Deployment / Release:**
1. Run `helm dependency update k8s/observability`.
2. Ensure `chatapp-secrets` exists.
3. Deploy Local: `helm upgrade --install observability k8s/observability -f k8s/observability/values-local.yaml`
4. Deploy GKE: `helm upgrade --install observability k8s/observability -f k8s/observability/values-gke.yaml`

### 5. Connecting the App to the Observability Stack

For the application and the observability stack to discover and send data to each other, the application needs to point to the correct service endpoints exposed by the Helm release of the observability stack.

#### Port & Endpoints Mapping
When the observability stack is deployed with the Helm release name `observability` (e.g., in the same namespace):
- **Loki Push URL**: `http://observability-loki:3100/loki/api/v1/push` (or `http://observability-loki.<namespace>.svc.cluster.local:3100/loki/api/v1/push`)
- **Tempo OTLP Tracing (HTTP)**: `http://observability-tempo:4318/v1/traces` (or `http://observability-tempo.<namespace>.svc.cluster.local:4318/v1/traces`)
- **Prometheus Scrape**: Prometheus will scrape metrics from the application if the application has the following annotations on its pod or service:
  ```yaml
  prometheus.io/scrape: "true"
  prometheus.io/path: "/actuator/prometheus"
  prometheus.io/port: "8081"
  ```
  Alternatively, configure a `ServiceMonitor` targeting the application's service.

#### Environment Variables Binding
In the application's Helm values profile or Deployment manifest, bind these service endpoints using environment variables:

```yaml
env:
  LOKI_URL: "http://observability-loki:3100/loki/api/v1/push"
  OTLP_ENDPOINT: "http://observability-tempo:4318/v1/traces"
```

In the Spring Boot configuration (`application-prod.yml` or `application.yml`):
```yaml
loki:
  url: ${LOKI_URL}

management:
  otlp:
    tracing:
      endpoint: ${OTLP_ENDPOINT}
```

## Advanced features

- **Tracing:** Probability set to 1.0 by default.
- **Log Aggregation:** Loki integration via `Loki4jAppender` in Logback.
