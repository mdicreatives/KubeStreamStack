# Local Development Setup Guide

This guide provides instructions for setting up your local environment to develop applications and components that interact with or run on the KubeStreamStack platform. This includes developing Flink jobs, Airflow DAGs, and custom Kafka producers/consumers.

## 1. Overview of Local Development Workflow

The typical local development workflow involves:
1.  Ensuring your KubeStreamStack platform is running on Minikube.
2.  Developing your application code (e.g., Flink job, Python script).
3.  Building your application (if necessary, e.g., compiling a Flink JAR).
4.  Deploying or running your application against the local KubeStreamStack services.
5.  Testing and debugging.

## 2. Prerequisites for Development

In addition to the [general prerequisites](../deployment/prerequisites.md) for running KubeStreamStack, you'll need:

*   **Integrated Development Environment (IDE)**:
    *   For Java/Scala Flink applications: IntelliJ IDEA, Eclipse.
    *   For Python Airflow DAGs/Kafka scripts: VS Code, PyCharm.
*   **Git**: For version control.
*   **Docker Desktop / Docker Engine**: While Minikube handles Kubernetes, having Docker locally can be useful for building custom images if your development workflow requires it.
*   **Kubernetes Client Tools**: `kubectl` (already a prerequisite for running the platform).
*   **Helm**: (already a prerequisite for running the platform).
*   **Python Development Environment**: For Kafka producer/consumer examples and Airflow DAGs.
    *   `pip` for package management.
    *   `kafka-python` library (for Python Kafka clients).

## 3. Start the KubeStreamStack Platform

Before you can develop against the platform, ensure it's running in your local Minikube cluster.

1.  **Clone the repository** (if you haven't already):
    ```bash
    git clone https://github.com/mdicreatives/KubeStreamStack.git
    cd KubeStreamStack
    ```
2.  **Start Minikube** with sufficient resources (as recommended in the [Installation Guide](../deployment/installation.md)):
    ```bash
    minikube start --memory 8192mb --cpus 4 --disk-size 50g
    ```
3.  **Deploy the platform components**:
    ```bash
    ./scripts/platform-manager.sh start
    ```
    Verify all pods are running using `kubectl get pods`.

## 4. Accessing Services from Localhost

To allow your locally running development applications (e.g., Flink client, Python scripts) to connect to services inside Minikube, you'll often need to use `minikube service` or `kubectl port-forward`.

*   **Kafka Broker (for producers/consumers)**:
    ```bash
    minikube service kafka --url
    # Or manually port-forward:
    # kubectl port-forward service/kafka 9092:9092
    ```
    Use the returned URL/IP and port (e.g., `http://192.168.49.2:9092` or `localhost:9092` if port-forwarded) as your Kafka bootstrap server.

*   **Flink JobManager (for submitting jobs)**:
    ```bash
    minikube service flink-jobmanager --url
    # Or manually port-forward:
    # kubectl port-forward service/flink-jobmanager 8081:8081
    ```
    Use the returned URL/IP and port (e.g., `http://192.168.49.2:8081` or `localhost:8081` if port-forwarded) as your Flink JobManager address.

*   **Airflow Webserver (for UI access)**:
    ```bash
    minikube service airflow-webserver --url
    # Or manually port-forward:
    # kubectl port-forward service/airflow-webserver 8080:8080
    ```

## 5. Developing Flink Applications

### Project Structure
Flink applications are typically Maven or Gradle projects. The example Flink application is located at `examples/flink-kafka-app`.

### Building Flink Jobs
1.  Navigate to your Flink application's root directory (e.g., `examples/flink-kafka-app`).
2.  Build the fat JAR using Maven:
    ```bash
    mvn clean package
    ```
    This will create a JAR file in the `target/` directory (e.g., `target/flink-kafka-processor-1.0-SNAPSHOT.jar`).

### Submitting Flink Jobs to Minikube
You can submit the built JAR to your running Flink cluster in Minikube.

1.  Ensure you have the Flink client installed locally, or you can use `kubectl exec` into a Flink client pod if your Helm chart provides one.
2.  Get the Flink JobManager address (see "Accessing Services from Localhost" above).
3.  Submit the job:
    ```bash
    flink run -m <flink-jobmanager-address>:8081 path/to/your/flink-job.jar
    ```
    For the example application:
    ```bash
    cd examples/flink-kafka-app
    flink run -m $(minikube service flink-jobmanager --url | sed 's|http://||') target/flink-kafka-processor-1.0-SNAPSHOT.jar
    ```
    *Note: The `sed` command is used to strip `http://` from the `minikube service` output, as `flink run -m` expects just the host:port.*

### IDE Setup for Flink
Import your Flink application (e.g., `examples/flink-kafka-app`) into your IDE as a Maven project. You can run and debug Flink applications locally within your IDE, often by setting up a local Flink mini-cluster for testing, or by configuring your application to connect to the remote Flink cluster in Minikube.

## 6. Developing Apache Airflow DAGs

### DAGs Folder
Airflow DAGs are typically Python files placed in a designated DAGs folder. In a Kubernetes deployment, this folder is usually mounted as a Persistent Volume or synced from a Git repository.

To develop DAGs locally and have them picked up by your Airflow deployment in Minikube:

1.  **Identify the DAGs folder**: Check your Airflow Helm chart configuration (or the `platform-manager.sh` script) to see where the `dags` volume is mounted or how DAGs are synced. Common paths are `/opt/airflow/dags` or `/usr/local/airflow/dags` inside the Airflow pods.
2.  **Sync DAGs**:
    *   **Manual Copy**: The simplest way for local development is to manually copy your DAG files into the Airflow webserver and scheduler pods. This is not scalable but works for quick tests.
        ```bash
        kubectl cp my_dag.py <airflow-webserver-pod-name>:/opt/airflow/dags/my_dag.py
        kubectl cp my_dag.py <airflow-scheduler-pod-name>:/opt/airflow/dags/my_dag.py
        ```
    *   **Persistent Volume Mount**: If your Airflow Helm chart uses a Persistent Volume for DAGs, you might be able to mount that volume locally (e.g., using `minikube mount`) or use a shared volume that both your local machine and the Minikube pods can access.
    *   **Git Sync (Recommended for Production-like Dev)**: For a more robust development setup, configure your Airflow Helm chart to use a Git Sync sidecar container. This allows Airflow to automatically pull DAGs from a Git repository (e.g., a local Git server or a public/private GitHub repo). You would push your DAG changes to Git, and Airflow would pick them up.

### Testing DAGs Locally
You can test individual DAGs or tasks locally using the Airflow CLI without deploying them to the cluster, which is faster for iterative development:

```bash
# Navigate to your DAGs folder
cd path/to/your/dags

# Test a specific task in a DAG
airflow tasks test <dag_id> <task_id> <ds>

# Example:
airflow tasks test my_example_dag my_first_task 2023-01-01
```
*Note: This requires a local Airflow installation with its own backend database, or careful configuration to point to the Minikube PostgreSQL. For simple syntax checks, a local installation is sufficient.*

## 7. Developing Kafka Producers and Consumers

### Python Clients
The `examples/kafka-producer` and `examples/kafka-consumer` directories contain simple Python scripts.

1.  Install the necessary library:
    ```bash
    pip install kafka-python
    ```
2.  Ensure Kafka is accessible via port-forwarding or `minikube service kafka --url`.
3.  Run the scripts:
    ```bash
    # In examples/kafka-producer
    python producer.py

    # In examples/kafka-consumer
    python consumer.py
    ```
    Modify the `KAFKA_BROKER` variable in these scripts to match your Kafka service address.

### Java Clients
For Java-based Kafka clients, you would create a Maven/Gradle project and include the `kafka-clients` dependency.

```xml
<dependency>
    <groupId>org.apache.kafka</groupId>
    <artifactId>kafka-clients</artifactId>
    <version>3.5.1</version> <!-- Use a version compatible with your Kafka cluster -->
</dependency>
```
Then, configure your producer/consumer to connect to the Kafka broker address obtained from Minikube.

## 8. General Development Tips

*   **Logging**: Ensure your applications log sufficiently. Use `kubectl logs <pod-name>` to view logs from your deployed components.
*   **Debugging**: For remote debugging of Java applications (like Flink jobs) running in Kubernetes, you can configure the JVM to open a debug port and then `kubectl port-forward` that port to your local machine, allowing your IDE to connect.
*   **Resource Management**: Be mindful of the resources allocated to your Minikube VM. If applications crash or perform poorly, increase memory and CPU.
*   **Clean Up**: When done with development, you can stop the platform and Minikube to free up resources:
    ```bash
    ./scripts/platform-manager.sh stop
    minikube stop
    ```
    To completely reset Minikube:
    ```bash
    minikube delete
    ```

This guide should provide a solid foundation for developing on KubeStreamStack.
