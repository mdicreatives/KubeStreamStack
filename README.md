# Rental Car Streaming Platform

A complete streaming data platform for processing real-time GPS and rental car data using Apache Kafka, Flink, and Airflow.

## Table of Contents
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Development](#development)
- [Troubleshooting](#troubleshooting)
- [Security](#security)
- [Pause and Resume Helm Resources](#pause-and-resume-helm-resources)

## Architecture

### Components
- **Apache Kafka**: Message broker for real-time data ingestion
- **Kafka UI**: Web interface for Kafka management
- **Apache Flink**: Stream processing engine
- **Apache Airflow**: Workflow orchestration
- **PostgreSQL**: Metadata storage for Airflow

### Project Structure
```bash
.
├── README.md
├── data-generator/
│   └── gps_data_generator.py
├── flink-jobs/
│   ├── pom.xml
│   └── src/
│       └── main/
│           └── java/
│               └── com/
│                   └── rental/
│                       └── streaming/
│                           └── GpsStreamProcessor.java
└── streaming-platform/
    ├── Chart.yaml
    ├── values.yaml
    └── charts/
        ├── kafka/
        ├── kafkaui/
        ├── flink/
        └── airflow/
```

## Prerequisites

- Minikube v1.30+
- kubectl v1.25+
- Helm 3.11+
- Java 11
- Maven 3.8+
- Python 3.8+

## Installation

### 1. Start Minikube
```bash
# Start with sufficient resources
minikube start --cpus=6 --memory=10240m --disk-size=10g

# Enable required addons
minikube addons enable storage-provisioner
minikube addons enable default-storageclass
```

### 2. Create Namespace
```bash
kubectl create namespace dev-env
```

### 3. Build Flink Job
```bash
cd flink-jobs
mvn clean package
cd ..
```

### 4. Deploy Using Helm
```bash
cd streaming-platform
helm dependency update
helm install streaming-platform . -n dev-env
```

## Configuration

### Resource Limits

```yaml
# Default resource configurations in values.yaml
kafka:
  resources:
    limits:
      memory: "1Gi"
      cpu: "500m"
    requests:
      memory: "512Mi"
      cpu: "250m"

flink:
  resources:
    limits:
      memory: "2Gi"
      cpu: "1000m"

airflow:
  resources:
    limits:
      memory: "2Gi"
      cpu: "1000m"
```

## Usage

### Access Services

1. Start port forwarding:
```bash
# Kafka UI
kubectl port-forward svc/kafka-ui 8080:8080 -n dev-env &

# Flink UI
kubectl port-forward svc/flink-jobmanager 8081:8081 -n dev-env &

# Airflow UI
kubectl port-forward svc/airflow-webserver 8082:8080 -n dev-env &


# Postgres UI
kubectl port-forward svc/airflow-postgres 5432:5432 -n dev-env &

#Kafka External Access
kubectl port-forward svc/kafka 9094:9094 -n dev-env &

```


2. Access UIs:
- Kafka UI: http://localhost:8080
- Flink UI: http://localhost:8081
- Airflow UI: http://localhost:8082
- Postgres UI: http://localhost:5432

### Helm Commands

```bash
# Update dependencies
helm dependency update

# Install chart
helm install streaming-platform . -n dev-env

# Upgrade deployment
helm upgrade streaming-platform . -n dev-env

# Install/Upgrade combined
helm upgrade --install streaming-platform . -n dev-env

# List releases
helm list -n dev-env

# Rollback to previous version
helm rollback streaming-platform 1 -n dev-env

# Uninstall
helm uninstall streaming-platform -n dev-env
```

### Monitoring

```bash
# Check pod status
kubectl get pods -n dev-env

# Watch pods
kubectl get pods -n dev-env -w

# View logs
kubectl logs -f deployment/kafka -n dev-env
kubectl logs -f deployment/airflow-webserver -n dev-env
kubectl logs -f deployment/flink-jobmanager -n dev-env

# Check resources
kubectl top pods -n dev-env
```

## Development

### Modify Flink Job

1. Update code in `flink-jobs/src/main/java/com/rental/streaming/`
2. Build the job:
```bash
cd flink-jobs
mvn clean package
```

### Update Helm Charts

1. Modify charts in `streaming-platform/charts/`
2. Update deployment:
```bash
helm dependency update
helm upgrade streaming-platform . -n dev-env
```

## Troubleshooting

### Common Issues

1. Pods not starting:
```bash
kubectl describe pod <pod-name> -n dev-env
```

2. Connection issues:
```bash
# Check services
kubectl get svc -n dev-env

# Check endpoints
kubectl get endpoints -n dev-env
```

3. Storage issues:
```bash
kubectl get pv,pvc -n dev-env
```

### Quick Fixes

1. Restart deployments:
```bash
kubectl rollout restart deployment <deployment-name> -n dev-env
```

2. Reset environment:
```bash
helm uninstall streaming-platform -n dev-env
kubectl delete namespace dev-env
kubectl create namespace dev-env
helm install streaming-platform . -n dev-env
```

## Security

### Current Setup (Development)
- Default credentials used
- Basic authentication disabled
- No encryption in transit
- No resource quotas

### Production Recommendations
1. Enable Authentication:
   - Implement Kafka SASL/SSL
   - Enable Airflow authentication
   - Configure Flink security

2. Use Secrets Management:
   - Store credentials in Kubernetes secrets
   - Implement proper secret rotation

3. Network Security:
   - Configure network policies
   - Enable TLS/SSL
   - Implement proper ingress controls

4. Resource Management:
   - Set appropriate resource limits
   - Implement pod security policies
   - Configure proper node affinity

## Pause and Resume Helm Resources

To safely shut down your Linux system and resume your Kubernetes resources managed by Helm, follow these steps:

### Pause Resources

1. **Scale Down Deployments and StatefulSets:**

   Scale down all deployments and statefulsets to zero replicas to pause workloads.

   ```bash
   # Scale down all deployments
   kubectl scale deployment --all --replicas=0 -n dev-env

   # Scale down all statefulsets
   kubectl scale statefulset --all --replicas=0 -n dev-env
   ```

2. **Verify Scaling:**

   Ensure all pods are terminated.

   ```bash
   kubectl get pods -n dev-env
   ```

### Shutdown Linux

You can now safely shut down your Linux system.

```bash
sudo shutdown -h now
```

### Resume Resources

1. **Start Linux:**

   Boot up your Linux system.

2. **Start Minikube:**

   If using Minikube, start it again.

   ```bash
   minikube start
   ```

3. **Scale Up Deployments and StatefulSets:**

   Scale your deployments and statefulsets back to their original replica count.

   ```bash
   # Scale up all deployments (replace <original-replica-count> with the actual number)
   kubectl scale deployment --all --replicas=<original-replica-count> -n dev-env

   # Scale up all statefulsets (replace <original-replica-count> with the actual number)
   kubectl scale statefulset --all --replicas=<original-replica-count> -n dev-env
   ```

4. **Verify Scaling:**

   Check that all pods are running as expected.

   ```bash
   kubectl get pods -n dev-env
   ```

## Cleanup

```bash
# Remove deployment
helm uninstall streaming-platform -n dev-env

# Delete namespace
kubectl delete namespace dev-env

# Stop Minikube
minikube stop

# Delete cluster
minikube delete
```

#airflow commands
Airflow user creation
```bash
airflow users  create --role Admin --username admin --email admin --firstname admin --lastname admin --password admin
```


