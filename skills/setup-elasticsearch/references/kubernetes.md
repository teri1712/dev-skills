# Kubernetes Setup for Elasticsearch

This reference document outlines how to deploy Elasticsearch in a Kubernetes (K8s) cluster using both native manifest YAML files and Helm charts.

## Method 1: Using Helm (Recommended)

Helm is the standard and easiest way to deploy Elasticsearch in Kubernetes. The official Elastic Helm charts or the Bitnami charts are widely used.

### Using Bitnami Helm Chart
The Bitnami chart is popular for standard single-node or clustered deployments.

```bash
# Add the Bitnami repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install a single-node Elasticsearch deployment for development/testing
helm install elasticsearch bitnami/elasticsearch \
  --set global.security.enabled=false \
  --set master.replicaCount=1 \
  --set cooridnation.service.enabled=false \
  --set data.replicaCount=0 \
  --set ingest.replicaCount=0
```

### Using Elastic Official Helm Chart
```bash
helm repo add elastic https://helm.elastic.co
helm repo update

# Install Elasticsearch
helm install elasticsearch elastic/elasticsearch --version 8.11.1
```

---

## Method 2: Kubernetes Manifests (StatefulSet)

If you prefer static manifest files without Helm, you can use the following standard single-node StatefulSet configuration.

### 1. Persistent Volume Claim (`elasticsearch-pvc.yaml`)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: elasticsearch-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

### 2. Service (`elasticsearch-service.yaml`)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
  labels:
    app: elasticsearch
spec:
  ports:
    - port: 9200
      name: http
    - port: 9300
      name: transport
  selector:
    app: elasticsearch
  type: ClusterIP
```

### 3. StatefulSet (`elasticsearch-statefulset.yaml`)
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: elasticsearch
spec:
  serviceName: "elasticsearch"
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      securityContext:
        fsGroup: 1000
      containers:
      - name: elasticsearch
        image: docker.elastic.co/elasticsearch/elasticsearch:8.11.1
        resources:
          limits:
            cpu: "1000m"
            memory: "2Gi"
          requests:
            cpu: "100m"
            memory: "1Gi"
        ports:
        - containerPort: 9200
          name: http
        - containerPort: 9300
          name: transport
        env:
        - name: discovery.type
          value: single-node
        - name: xpack.security.enabled
          value: "false"
        - name: ES_JAVA_OPTS
          value: "-Xms512m -Xmx512m"
        volumeMounts:
        - name: elasticsearch-data
          mountPath: /usr/share/elasticsearch/data
      initContainers:
      # Fix virtual memory limit on the K8s node
      - name: sysctl
        image: busybox:latest
        imagePullPolicy: IfNotPresent
        command: ["sysctl", "-w", "vm.max_map_count=262144"]
        securityContext:
          privileged: true
      volumes:
      - name: elasticsearch-data
        persistentVolumeClaim:
          claimName: elasticsearch-data
```
