---
name: setup-elasticsearch
description: Set up, deploy, and configure Elasticsearch for Kubernetes, Docker Compose, or Spring Boot applications. Use when asked to setup Elasticsearch, deploy it to K8s/Helm, add it to docker-compose, configure connection settings, or check ES connection.
---

# Setup Elasticsearch

This skill assists in setting up and configuring Elasticsearch (version 8.x) for development (Docker Compose), testing (Testcontainers), and production (Kubernetes) environments, as well as integrating it with Spring Boot.

## Workflow Decision Tree

Identify the environment or requirement:
1. **Docker Compose (Local Development)**: Refer to the Docker Compose setup guidelines.
2. **Testcontainers (Integration Testing)**: Refer to the Testcontainers configuration guidelines.
3. **Kubernetes / Helm (Deployment)**: Refer to the Kubernetes deployment guidelines.
4. **Application Connection (Spring Boot)**: Integrate the connection properties and dependencies.

---

## 1. Docker Compose (Local Dev)
Refer to [docker-compose.md](file:///home/decade/.gemini/skills/setup-elasticsearch/references/docker-compose.md) for the ready-to-use Compose template.
- Mount volume data at `/usr/share/elasticsearch/data` for persistence.
- Set `-Xms512m -Xmx512m` as standard heap bounds.
- Set host's `vm.max_map_count=262144`.

## 2. Testcontainers (Integration Testing)
Refer to [testcontainers.md](file:///home/decade/.gemini/skills/setup-elasticsearch/references/testcontainers.md) for configuring Elasticsearch with Testcontainers.
- Use `@ServiceConnection` and `@Bean` on the `ElasticsearchContainer` (Spring Boot 3.1+).
- Run Elasticsearch 8.17.0 with security disabled (`xpack.security.enabled=false`) for local tests.

## 3. Kubernetes Deployment
Refer to [kubernetes.md](file:///home/decade/.gemini/skills/setup-elasticsearch/references/kubernetes.md) for Helm command guidelines and the StatefulSet manifest template.
- Prefer Helm (e.g., Bitnami or Elastic repository) for managed clusters.
- Use StatefulSet manifests with a PersistentVolumeClaim for custom setups.
- Use a privileged initContainer to adjust `vm.max_map_count` configuration automatically on the node.

## 4. Spring Boot Connectivity
Refer to [spring-boot-binding.md](file:///home/decade/.gemini/skills/setup-elasticsearch/references/spring-boot-binding.md) for Spring Data configuration.
- Add `spring-boot-starter-data-elasticsearch` dependency.
- Configure `spring.elasticsearch.uris` in properties/YAML.
- Implement High-Level Rest Client customizations if self-signed certificates are in use.

## 5. Connection Verification
Run the helper script `test-es-connection.sh` located in [scripts/test-es-connection.sh](file:///home/decade/.gemini/skills/setup-elasticsearch/scripts/test-es-connection.sh) to verify connectivity:
```bash
bash /home/decade/.gemini/skills/setup-elasticsearch/scripts/test-es-connection.sh [ES_URL]
```

