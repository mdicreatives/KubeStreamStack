# KubeStreamStack

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![CI/CD](https://github.com/mdicreatives/KubeStreamStack/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/mdicreatives/KubeStreamStack/actions/workflows/ci-cd.yml)

A Development-ready streaming platform built with Apache Kafka, Flink, and Airflow, designed for real-time data processing applications.

## 🌟 Features

- Real-time data ingestion with Apache Kafka
- Stream processing with Apache Flink
- Workflow orchestration with Apache Airflow
- Web-based monitoring interfaces
- Automated deployment and management
- Scalable and production-ready architecture
- Easy integration with custom applications

## 🏗 Architecture

The platform consists of several key components:

- **Apache Kafka**: Message broker for real-time data ingestion
- **Kafka UI**: Web interface for Kafka management
- **Apache Flink**: Stream processing engine
- **Apache Airflow**: Workflow orchestration
- **PostgreSQL**: Metadata storage for Airflow

For detailed architecture documentation, see [System Overview](documentation/architecture/system-overview.md).

## 🚀 Quick Start

To get KubeStreamStack up and running quickly:

### Prerequisites

Ensure you have the necessary tools installed: Minikube, kubectl, Helm, Java 11, Maven, and Python 3.8+.
For detailed prerequisites, see the [Prerequisites Guide](documentation/deployment/prerequisites.md).

### Installation

1.  Clone the repository:
    ```bash
    git clone https://github.com/mdicreatives/KubeStreamStack.git
    cd KubeStreamStack
    ```
2.  Run the platform manager script to deploy all components to your Minikube cluster:
    ```bash
    ./scripts/platform-manager.sh start
    ```
For detailed installation instructions and post-installation steps (like Airflow user creation), refer to the [Installation Guide](documentation/deployment/installation.md).

## 📚 Documentation

- [System Architecture](documentation/architecture/system-overview.md)
- [Component Interaction](documentation/architecture/component-interaction.md)
- [Deployment Guide](documentation/deployment/installation.md)
- [Configuration Guide](documentation/deployment/configuration.md)
- [Development Guide](documentation/development/local-setup.md)
- [Examples](examples/README.md)

## 🛠 Development

### Local Development Setup

Follow the [Local Setup Guide](documentation/development/local-setup.md) for detailed instructions on setting up your development environment, building applications, and interacting with the platform.

### Building from Source

To build the platform components or custom applications from source:

1.  Navigate to the relevant source directory (e.g., `src/KubeStreamStack` for Helm charts, `examples/flink-kafka-app` for Flink jobs).
2.  Update Helm chart dependencies (if applicable):
    ```bash
    helm dependency update
    ```
3.  Follow specific build instructions for individual components (e.g., `mvn clean package` for Java applications).
Refer to the [Development Guide](documentation/development/local-setup.md) for more details.

## 🔧 Configuration

The platform can be configured through Helm values. See the [Configuration Guide](documentation/deployment/configuration.md) for details on how to customize your deployment.

## 📊 Monitoring

Access the various web UIs for monitoring and management. You might need to use `minikube service <service-name> --url` or set up port-forwarding to access them.

-   **Kafka UI**: `http://localhost:8080` (example port)
-   **Flink UI**: `http://localhost:8081` (example port)
-   **Airflow UI**: `http://localhost:8082` (example port)
-   **PostgreSQL**: Database port `5432` (not a web UI)

For detailed access methods, refer to the [Installation Guide](documentation/deployment/installation.md) and [Configuration Guide](documentation/deployment/configuration.md).

## 🔐 Security

For security considerations and best practices, see the [Security Guide](documentation/deployment/security.md).

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Apache Kafka
- Apache Flink
- Apache Airflow
- Kubernetes
- Helm


