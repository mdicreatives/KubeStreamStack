# Configuration Guide

KubeStreamStack leverages Helm charts for deploying its core components (Kafka, Flink, Airflow, PostgreSQL). This guide explains how to configure these components by overriding their default Helm values.

## 1. Understanding Helm Values

Each Helm chart comes with a set of default configuration values, typically defined in a `values.yaml` file within the chart. You can inspect these default values for any installed chart using:

```bash
helm show values <repo-name>/<chart-name>
```
For example, to see Kafka chart values:
```bash
helm show values bitnami/kafka
```

## 2. Overriding Default Values

You can customize the deployment by providing your own `values.yaml` file or by passing individual `--set` flags during the `helm install` or `helm upgrade` command.

The `platform-manager.sh` script in this project uses a simplified approach. To customize, you would typically modify the Helm commands within that script or create a custom `values.yaml` file and reference it.

### Example: Modifying `platform-manager.sh`

Let's say you want to change the number of Kafka replicas or Flink TaskManagers. You would locate the `helm install` or `helm upgrade` command for the respective component in `scripts/platform-manager.sh` and add your desired `--set` flags or a `-f` flag pointing to a custom values file.

**Original (simplified example from script):**
```bash
helm upgrade --install kafka bitnami/kafka -n default
```

**With custom values (example):**

To change Kafka replicas to 3 and Flink TaskManagers to 2:

```bash
# For Kafka
helm upgrade --install kafka bitnami/kafka -n default \
  --set replicaCount=3 \
  --set zookeeper.replicaCount=3

# For Flink
helm upgrade --install flink flink-operator/flink -n default \
  --set jobmanager.replicas=1 \
  --set taskmanager.replicas=2 \
  --set jobmanager.resource.memory=2048m \
  --set taskmanager.resource.memory=4096m
```

### Using a Custom Values File

For more extensive configurations, it's better to create a separate YAML file (e.g., `my-custom-values.yaml`) and pass it to Helm:

```yaml
# my-custom-values.yaml
kafka:
  replicaCount: 3
  zookeeper:
    replicaCount: 3
flink:
  jobmanager:
    replicas: 1
    resource:
      memory: 2048m
      cpu: 1
  taskmanager:
    replicas: 2
    resource:
      memory: 4096m
      cpu: 2
airflow:
  executor: KubernetesExecutor # Example: change executor type
  webserver:
    resources:
      limits:
        cpu: 1
        memory: 2Gi
```

Then, modify the `platform-manager.sh` script to use this file:

```bash
# In platform-manager.sh, for each component:
helm upgrade --install kafka bitnami/kafka -n default -f my-custom-values.yaml
helm upgrade --install flink flink-operator/flink -n default -f my-custom-values.yaml
helm upgrade --install airflow apache-airflow/airflow -n default -f my-custom-values.yaml
# ... and so on for other components
```
*Note: When using a single `my-custom-values.yaml` for multiple charts, ensure the values are nested under the chart's release name or a top-level key that the chart expects if it's designed for a parent chart. For individual charts, the top-level keys in `my-custom-values.yaml` directly correspond to the chart's `values.yaml` structure.*

## 3. Common Configuration Areas

Here are some common configuration parameters you might want to adjust:

### Apache Kafka

*   **`replicaCount`**: Number of Kafka brokers.
*   **`zookeeper.replicaCount`**: Number of Zookeeper nodes.
*   **`resources`**: CPU and memory limits/requests for Kafka and Zookeeper pods.
*   **`persistence.size`**: Size of Persistent Volume Claims for data storage.
*   **`listeners`**: Network listeners configuration (e.g., for external access).

### Apache Flink

*   **`jobmanager.replicas`**: Number of Flink JobManagers.
*   **`taskmanager.replicas`**: Number of Flink TaskManagers.
*   **`jobmanager.resource`**: CPU and memory for JobManager.
*   **`taskmanager.resource`**: CPU and memory for TaskManager.
*   **`configuration`**: Flink-specific configurations (e.g., `taskmanager.numberOfTaskSlots`).

### Apache Airflow

*   **`executor`**: Type of executor (e.g., `CeleryExecutor`, `KubernetesExecutor`).
*   **`webserver.resources`**: CPU and memory for the Airflow webserver.
*   **`scheduler.resources`**: CPU and memory for the Airflow scheduler.
*   **`worker.resources`**: CPU and memory for Airflow workers (if using Celery/Kubernetes executor).
*   **`postgresql.enabled`**: Whether to deploy an embedded PostgreSQL (usually `true` for default setup).
*   **`config`**: Airflow configuration overrides (e.g., `core.dags_folder`).

### PostgreSQL (Airflow Backend)

*   **`primary.persistence.size`**: Size of Persistent Volume Claim for PostgreSQL data.
*   **`primary.resources`**: CPU and memory for the PostgreSQL pod.

## 4. Applying Changes

After modifying the `platform-manager.sh` script or your custom `values.yaml` file, simply re-run the start command:

```bash
./scripts/platform-manager.sh start
```
Helm will detect the changes and perform an `upgrade` operation, applying your new configurations to the running components.

Always refer to the official Helm chart documentation for each component for a complete list of configurable values and their descriptions.
*   [Bitnami Kafka Helm Chart](https://artifacthub.io/packages/helm/bitnami/kafka)
*   [Apache Airflow Helm Chart](https://artifacthub.io/packages/helm/apache-airflow/airflow)
*   [Flink Kubernetes Operator (if used for Flink deployment)](https://nightlies.apache.org/flink/flink-kubernetes-operator-docs-main/docs/custom-resource/overview/) (Note: The current setup might use a simpler Flink Helm chart, verify which one is used in `platform-manager.sh`)
