# KubeStreamStack Examples

This directory contains example applications to demonstrate the capabilities of the KubeStreamStack platform.

## Flink Kafka Processor Example

This example showcases a simple Apache Flink application that reads messages from one Kafka topic, transforms them (converts to uppercase and adds a timestamp), and writes the processed messages to another Kafka topic.

### Prerequisites for this Example

*   KubeStreamStack platform running (Kafka, Flink, etc.)
*   Python 3.x and `pip` for running producer/consumer scripts.
*   Java 11 and Maven 3.8+ (if you plan to build the Flink application locally).
*   Poetry (recommended) or venv for Python dependency management.

### Setting up Python Environment

#### Option 1: Using Poetry (Recommended)

1. Install Poetry if you haven't already:
   ```bash
   curl -sSL https://install.python-poetry.org | python3 -
   ```

2. Navigate to the examples directory:
   ```bash
   cd examples
   ```

3. Initialize Poetry project:
   ```bash
   poetry init
   ```
   - Accept the defaults for most prompts
   - Add `kafka-python` as a dependency when prompted
   - Or add it later using: `poetry add kafka-python`

4. Activate the virtual environment:
   ```bash
   poetry shell
   ```

#### Option 2: Using venv

1. Create a virtual environment:
   ```bash
   python -m venv venv
   ```

2. Activate the virtual environment:
   ```bash
   # On Linux/macOS
   source venv/bin/activate
   # On Windows
   .\venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install kafka-python
   ```

### 1. Ensure KubeStreamStack is Running

Make sure your KubeStreamStack environment is up and running. You can start it using the platform manager script:

```bash
cd ../.. # Navigate back to the root of the KubeStreamStack project
./scripts/platform-manager.sh start
```

### 2. Create Kafka Topics

The Flink application requires two Kafka topics: an input topic and an output topic. You can create these using the Kafka UI or `kubectl exec` into a Kafka broker pod.

Assuming Kafka is accessible via `localhost:9092` (e.g., through `minikube service kafka --url` or port-forwarding):

```bash
# Example using kafka-topics.sh (requires Kafka client tools)
# Replace 'kafka-broker-service:9092' with your actual Kafka broker address if not localhost
# You might need to port-forward Kafka service if running in Minikube:
# kubectl port-forward service/kafka 9092:9092

# Create input topic
kubectl exec -it <kafka-broker-pod-name> -- kafka-topics.sh --create --topic input-topic --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1

# Create output topic
kubectl exec -it <kafka-broker-pod-name> -- kafka-topics.sh --create --topic output-topic --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1
```
*Note: Replace `<kafka-broker-pod-name>` with the actual name of one of your Kafka broker pods (e.g., `kafka-0`). You can find it using `kubectl get pods | grep kafka`.*

### 3. Build and Deploy the Flink Application

#### Option A: Build Locally and Submit (Recommended for Development)

1.  Navigate to the Flink application directory:
    ```bash
    cd examples/flink-kafka-app
    ```
2.  Build the Flink application JAR:
    ```bash
    mvn clean package
    ```
    This will create a fat JAR (e.g., `target/flink-kafka-processor-1.0-SNAPSHOT.jar`) containing all dependencies.

3.  Submit the Flink job to your running Flink cluster. You'll need the Flink JobManager service URL. If running in Minikube, you can get it via:
    ```bash
    minikube service flink-jobmanager --url
    ```
    Let's assume the URL is `http://<flink-jobmanager-ip>:8081`.

    ```bash
    # Example Flink run command
    # Replace <flink-jobmanager-ip>:8081 with your actual Flink JobManager address
    # You might need to port-forward Flink JobManager if running in Minikube:
    # kubectl port-forward service/flink-jobmanager 8081:8081

    flink run -m <flink-jobmanager-ip>:8081 target/flink-kafka-processor-1.0-SNAPSHOT.jar
    ```
    *Note: The `flink` client command needs to be installed locally or you can use `kubectl exec` into a Flink client pod if available in your setup.*

#### Option B: Deploy via Helm (For Production-like Deployment)

This option would involve creating a dedicated Helm chart for your Flink application, which is beyond the scope of this basic example. However, in a production setup, you would containerize your Flink application and deploy it as a Flink job via a custom Helm chart or Flink Kubernetes Operator.

### 4. Run the Kafka Producer

This script will send sample messages to the `input-topic`.

1.  Make sure you're in your Poetry environment or venv:
    ```bash
    # If using Poetry
    poetry shell
    # If using venv
    source venv/bin/activate  # or .\venv\Scripts\activate on Windows
    ```

2.  Navigate to the producer script directory:
    ```bash
    cd kafka-producer
    ```

3.  Run the producer:
    ```bash
    python producer.py
    ```
    The producer will send 5 messages and then exit.

### 5. Run the Kafka Consumer

This script will read and display messages from the `output-topic`.

1.  Make sure you're in your Poetry environment or venv:
    ```bash
    # If using Poetry
    poetry shell
    # If using venv
    source venv/bin/activate  # or .\venv\Scripts\activate on Windows
    ```

2.  Navigate to the consumer script directory:
    ```bash
    cd kafka-consumer
    ```

3.  Run the consumer:
    ```bash
    python consumer.py
    ```
    The consumer will continuously listen for messages on `output-topic`. You should see the processed messages from the Flink application.

### 6. Verify the Output

After running the producer and consumer, you should see output similar to this in your consumer's terminal:

```
Received message: b'PROCESSED: HELLO WORLD - 2023-10-27 10:30:00'
Received message: b'PROCESSED: FLINK KAFKA EXAMPLE - 2023-10-27 10:30:01'
...
```
(Timestamps will vary)

This confirms that the Flink application is successfully reading from `input-topic`, processing the data, and writing to `output-topic`. 