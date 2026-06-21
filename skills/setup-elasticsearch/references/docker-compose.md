# Docker Compose Setup for Elasticsearch and Kibana

This reference provides a template and instructions for setting up Elasticsearch and Kibana locally for development.

## Docker Compose Configuration (`docker-compose-es.yml`)

The following YAML outlines a standard single-node Elasticsearch configuration (version 8.x) alongside Kibana with security features temporarily disabled or pre-configured for simple local development.

```yaml
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.1
    container_name: elasticsearch
    environment:
      - node.name=elasticsearch
      - cluster.name=es-docker-cluster
      - discovery.type=single-node
      # Disable security for simple local development (optional, adjust for production)
      - xpack.security.enabled=false
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es_data:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"
    healthcheck:
      test: ["CMD-SHELL", "curl -s http://localhost:9200/_cluster/health | grep -q '\"status\":\"green\"\\|\"status\":\"yellow\"'"]
      interval: 10s
      timeout: 5s
      retries: 5

  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.1
    container_name: kibana
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      elasticsearch:
        condition: service_healthy

volumes:
  es_data:
    driver: local
```

## Important Settings

1. **Virtual Memory (`vm.max_map_count`)**:
   Elasticsearch uses a `mmapfs` directory by default to store its indices. The default operating system limits on mmap counts may be too low, which can result in out-of-memory exceptions.
   On your Linux host, you must run:
   ```bash
   sudo sysctl -w vm.max_map_count=262144
   ```
   To make this permanent, add `vm.max_map_count=262144` to `/etc/sysctl.conf`.

2. **JVM Heap Size**:
   Configured via `ES_JAVA_OPTS`. Set `-Xms512m -Xmx512m` (or more, depending on your RAM) to ensure the JVM has enough heap space, but doesn't consume all system memory.

3. **Data Persistence**:
   A named volume `es_data` is mounted to `/usr/share/elasticsearch/data` to ensure data persists across container restarts and updates.
