# Kubernetes Setup for Elasticsearch (Nexa Project Pattern)

This reference outlines the exact production deployment configuration used for Elasticsearch in the Nexa project.

## 1. Helm Dependency Definition (`k8s/infra/Chart.yaml`)

The project uses the official Elastic Helm chart for Elasticsearch inside the `infra` chart dependencies:

```yaml
dependencies:
  - name: elasticsearch
    version: 8.5.1
    repository: https://helm.elastic.co/
```

---

## 2. Infrastructure Configuration (`k8s/infra/values.yaml`)

The infrastructure configurations are mapped under the `elasticsearch` key in `k8s/infra/values.yaml`:

```yaml
elasticsearch:
  replicas: 1
  minimumMasterNodes: 1
  protocol: https
  createCert: true
  secret:
    enabled: false
  extraEnvs:
    - name: ELASTIC_PASSWORD
      valueFrom:
        secretKeyRef:
          name: nexa-secrets
          key: elasticsearch-password
  tests:
    enabled: false
  esConfig:
    elasticsearch.yml: |
      cluster.routing.allocation.disk.watermark.low: 98%
      cluster.routing.allocation.disk.watermark.high: 99%
      cluster.routing.allocation.disk.watermark.flood_stage: 99.5%
```

- **Authentication**: Secured with HTTPS protocol using auto-created certificates (`createCert: true`).
- **Passwords**: Extracted from a Kubernetes Secret named `nexa-secrets` under the key `elasticsearch-password`.
- **Watermarks**: Custom low/high/flood stage watermarks applied inline within `elasticsearch.yml` configuration block to handle disk allocation tolerance.

---

## 3. Application Consumption Config (`k8s/nexa/values.yaml`)

The application deployment reads the connection settings via standard environment variable bindings mapping to properties in `application-prod.yaml`:

```yaml
env:
  ELASTICSEARCH_URL: "https://elasticsearch-master:9200"
  ELASTICSEARCH_USERNAME: "elastic"
  ELASTICSEARCH_PASSWORD:
    valueFrom:
      secretKeyRef:
        name: nexa-secrets
        key: elasticsearch-password
```
