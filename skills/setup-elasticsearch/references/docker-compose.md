# Docker Compose Setup for Elasticsearch (Nexa Project Pattern)

This reference outlines the exact Elasticsearch service configuration used in this project's local development stack.

## 1. Service Definition in `compose.yaml`

The project defines the Elasticsearch service in the root `compose.yaml` file:

```yaml
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.17.0
    environment:
      discovery.type: single-node
      xpack.security.enabled: "false"
      network.host: 0.0.0.0
      cluster.routing.allocation.disk.watermark.low: "98%"
      cluster.routing.allocation.disk.watermark.high: "99%"
      cluster.routing.allocation.disk.watermark.flood_stage: "99.5%"
    ports:
      - "9200:9200"
    cpus: 4
    mem_limit: 4g
    healthcheck:
      test: [ "CMD-SHELL", "curl -f http://localhost:9200/_cluster/health || exit 1" ]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 30s
    restart: always
```

### Key Configurations Explained

- **Image Version**: `8.17.0` (matching the Testcontainers and Production settings).
- **Security Disabled**: `xpack.security.enabled: "false"` simplifies local development interactions.
- **Disk Watermarks**: Adjusted watermarks (low: `98%`, high: `99%`, flood: `99.5%`) prevent the cluster from blocking index operations when the local disk space is running relatively low.
- **Resources**: CPU (`cpus: 4`) and memory limits (`mem_limit: 4g`) bound the host resources utilized by Elasticsearch.
- **Healthcheck**: Uses `curl` to verify cluster health status periodically.

## 2. Managing the Service

To spin up the Elasticsearch instance locally:

```bash
docker compose up -d elasticsearch
```

To view the service health and logs:

```bash
docker compose ps
docker compose logs -f elasticsearch
```
