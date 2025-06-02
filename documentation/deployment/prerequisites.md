# Prerequisites

This guide outlines the necessary tools and software required to set up and run KubeStreamStack. Ensure all prerequisites are installed and configured correctly before proceeding with the installation.

## 1. Minikube (v1.30+)

Minikube is a tool that runs a single-node Kubernetes cluster locally on your machine.

### Installation

*   **macOS (using Homebrew):**
    ```bash
    brew install minikube
    ```
*   **Linux (using curl):**
    ```bash
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    ```
*   **Windows (using Chocolatey):**
    ```bash
    choco install minikube
    ```
    *Alternatively, download the installer from the [Minikube releases page](https://minikube.sigs.k8s.io/docs/start/).*

### Verification

To verify Minikube installation:
```bash
minikube version
```

## 2. kubectl (v1.25+)

kubectl is the Kubernetes command-line tool that allows you to run commands against Kubernetes clusters.

### Installation

*   **macOS (using Homebrew):**
    ```bash
    brew install kubernetes-cli
    ```
*   **Linux (using apt-get for Debian/Ubuntu):**
    ```bash
    sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubectl
    ```
*   **Windows (using Chocolatey):**
    ```bash
    choco install kubernetes-cli
    ```
    *Alternatively, download the `kubectl.exe` from the [Kubernetes releases page](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/) and add it to your PATH.*

### Verification

To verify kubectl installation:
```bash
kubectl version --client
```

## 3. Helm (3.11+)

Helm is the package manager for Kubernetes, used to deploy and manage applications.

### Installation

*   **macOS (using Homebrew):**
    ```bash
    brew install helm
    ```
*   **Linux (using curl):**
    ```bash
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    ```
*   **Windows (using Chocolatey):**
    ```bash
    choco install kubernetes-helm
    ```
    *Alternatively, download the binary from the [Helm releases page](https://github.com/helm/helm/releases).*

### Verification

To verify Helm installation:
```bash
helm version
```

## 4. Java Development Kit (JDK 11)

Apache Flink requires a Java Development Kit. JDK 11 is recommended.

### Installation

*   **macOS (using Homebrew):**
    ```bash
    brew install openjdk@11
    sudo ln -sfn /usr/local/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk
    ```
    *You might need to set `JAVA_HOME` environment variable: `export JAVA_HOME="/usr/local/opt/openjdk@11"`*
*   **Linux (using apt-get for Debian/Ubuntu):**
    ```bash
    sudo apt update
    sudo apt install openjdk-11-jdk
    ```
*   **Windows:**
    Download and install JDK 11 from Oracle's website or use OpenJDK distributions like Adoptium (formerly AdoptOpenJDK). Ensure `JAVA_HOME` is set to your JDK installation directory and added to your system's PATH.

### Verification

To verify Java installation:
```bash
java -version
```

## 5. Apache Maven (3.8+)

Maven is a build automation tool used primarily for Java projects.

### Installation

*   **macOS (using Homebrew):**
    ```bash
    brew install maven
    ```
*   **Linux (using apt-get for Debian/Ubuntu):**
    ```bash
    sudo apt update
    sudo apt install maven
    ```
*   **Windows:**
    Download the Maven binary archive from the [Apache Maven website](https://maven.apache.org/download.cgi). Extract it and add the `bin` directory to your system's PATH.

### Verification

To verify Maven installation:
```bash
mvn -v
```

## 6. Python (3.8+)

Python is required for Apache Airflow and potentially for scripting.

### Installation

*   **macOS (using Homebrew):**
    ```bash
    brew install python@3.8 # or a newer 3.x version
    ```
*   **Linux (using apt-get for Debian/Ubuntu):**
    ```bash
    sudo apt update
    sudo apt install python3.8 python3-pip
    ```
*   **Windows:**
    Download the installer from the [official Python website](https://www.python.org/downloads/windows/). Ensure you check the "Add Python to PATH" option during installation.

### Verification

To verify Python installation:
```bash
python3 --version
```
