# Installation Guide

This guide provides detailed instructions on how to deploy the KubeStreamStack platform on your local Kubernetes cluster (Minikube).

## 1. Prerequisites Check

Before proceeding with the installation, ensure you have all the necessary prerequisites installed and configured on your system. Refer to the [Prerequisites Guide](prerequisites.md) for detailed instructions.

**Required Tools:**
*   Minikube v1.30+
*   kubectl v1.25+
*   Helm 3.11+
*   Java 11
*   Maven 3.8+
*   Python 3.8+

## 2. Clone the Repository

First, clone the KubeStreamStack repository to your local machine:

```bash
git clone https://github.com/mdicreatives/KubeStreamStack.git
cd KubeStreamStack
```

## 3. Start Minikube

Ensure your Minikube cluster is running. If it's not, start it with sufficient resources. A recommended setup for KubeStreamStack would be:

```bash
minikube start --memory 8192mb --cpus 4 --disk-size 50g
```
*   `--memory 8192mb`: Allocates 8GB of RAM to the Minikube VM. This is crucial for Flink and Kafka.
*   `--cpus 4`: Allocates 4 CPU cores.
*   `--disk-size 50g`: Allocates 50GB of disk space.

Wait for Minikube to fully start and for `kubectl` to be configured to use the Minikube context. You can verify this by running:

```bash
kubectl cluster-info
kubectl get nodes
```

## 4. Deploy KubeStreamStack Components

The project includes a `platform-manager.sh` script that automates the deployment of all core components (Kafka, Flink, Airflow, PostgreSQL) using their respective Helm charts.

To deploy the platform, run the `start` command:

```bash
./scripts/platform-manager.sh start
```

This script performs the following actions:
*   Adds necessary Helm repositories (e.g., Bitnami for Kafka, Airflow).
*   Updates Helm repositories.
*   Installs or upgrades the Helm charts for:
    *   Apache Kafka (and Zookeeper)
    *   Kafka UI
    *   Apache Flink
    *   Apache Airflow (with PostgreSQL as backend)

The deployment process might take several minutes, depending on your internet connection and system resources, as it involves pulling Docker images and deploying multiple Kubernetes resources.

## 5. Verify Deployment

After the `platform-manager.sh start` script completes, you can verify that all components are running correctly by checking the Kubernetes pods:

```bash
kubectl get pods -n default
```

You should see pods for Kafka (e.g., `kafka-0`, `kafka-1`), Zookeeper (`zookeeper-0`, `zookeeper-1`), Flink (`flink-jobmanager`, `flink-taskmanager-xxxx`), Airflow (`airflow-webserver`, `airflow-scheduler`, `airflow-worker`), and PostgreSQL (`postgresql-0`). All pods should eventually show a `Running` status.

## 6. Post-Installation Steps (Airflow User Creation)

For Airflow, you typically need to create an admin user to access the UI. Ensure the Airflow webserver pod is running and accessible (you might need to port-forward it first).

```bash
# Example: Port-forward Airflow webserver (if not using minikube service)
# kubectl port-forward service/airflow-webserver 8080:8080

# Then, execute the user creation command. You might need to exec into the webserver pod
# or use a dedicated Airflow client pod if your setup provides one.
# For simplicity, if Airflow CLI is available locally and configured to connect to the cluster:
airflow users create --role Admin --username admin --email admin@example.com --firstname admin --lastname user --password admin
```
*Note: The `airflow` command-line tool needs to be installed locally and configured to interact with your Airflow deployment, or you can `kubectl exec` into an Airflow pod (e.g., `airflow-webserver-xxxx`) and run the command inside the container.*

## 7. Accessing User Interfaces

You can access the web UIs for Kafka, Flink, and Airflow to monitor and manage your streaming platform. You might need to use `minikube service <service-name> --url` or set up port-forwarding to access them from your local machine.

Refer to the [Monitoring section in README.md](../../README.md#monitoring) for specific URLs and access methods.

Congratulations! Your KubeStreamStack is now installed and ready for use.
