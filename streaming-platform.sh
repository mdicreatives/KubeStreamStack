#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is not installed. Please install it first."
        exit 1
    fi
}

# Function to start the environment
start_environment() {
    print_status "Starting Minikube cluster..."
    minikube start --cpus=6 --memory=10240m --disk-size=10g

    print_status "Enabling required addons..."
    minikube addons enable storage-provisioner
    minikube addons enable default-storageclass

    print_status "Creating namespace..."
    kubectl create namespace dev-env

    print_status "Building Flink job..."
    cd flink-jobs
    mvn clean package
    cd ..

    print_status "Deploying streaming platform..."
    cd streaming-platform
    helm dependency update
    helm install streaming-platform . -n dev-env
    cd ..

    print_status "Starting port forwarding for UIs..."
    # Start port forwarding in background
    kubectl port-forward svc/kafka-ui 8080:8080 -n dev-env &
    kubectl port-forward svc/flink-jobmanager 8081:8081 -n dev-env &
    kubectl port-forward svc/airflow-webserver 8082:8080 -n dev-env &
    kubectl port-forward svc/airflow-postgres 5432:5432 -n dev-env &
    kubectl port-forward svc/kafka 9094:9094 -n dev-env &

    print_status "Environment is ready!"
    print_status "Access points:"
    echo "- Kafka UI: http://localhost:8080"
    echo "- Flink UI: http://localhost:8081"
    echo "- Airflow UI: http://localhost:8082"
    echo "- Postgres UI: localhost:5432"
    echo "- Kafka External Access: localhost:9094"
}

# Function to stop the environment
stop_environment() {
    print_status "Stopping port forwarding..."
    pkill -f "kubectl port-forward"

    print_status "Uninstalling Helm release..."
    helm uninstall streaming-platform -n dev-env

    print_status "Deleting namespace..."
    kubectl delete namespace dev-env

    print_status "Stopping Minikube..."
    minikube stop

    print_status "Environment stopped successfully!"
}

# Function to completely clean up
cleanup_environment() {
    print_status "Stopping port forwarding..."
    pkill -f "kubectl port-forward"

    print_status "Uninstalling Helm release..."
    helm uninstall streaming-platform -n dev-env

    print_status "Deleting namespace..."
    kubectl delete namespace dev-env

    print_status "Stopping Minikube..."
    minikube stop

    print_status "Deleting Minikube cluster..."
    minikube delete

    print_status "Environment cleaned up successfully!"
}

# Function to check environment status
check_status() {
    print_status "Checking environment status..."
    
    echo -e "\nMinikube status:"
    minikube status
    
    echo -e "\nNamespace status:"
    kubectl get ns dev-env
    
    echo -e "\nPod status:"
    kubectl get pods -n dev-env
    
    echo -e "\nService status:"
    kubectl get svc -n dev-env
}

# Main script
main() {
    # Check required commands
    check_command minikube
    check_command kubectl
    check_command helm
    check_command mvn

    case "$1" in
        "start")
            start_environment
            ;;
        "stop")
            stop_environment
            ;;
        "cleanup")
            cleanup_environment
            ;;
        "status")
            check_status
            ;;
        *)
            echo "Usage: $0 {start|stop|cleanup|status}"
            echo "  start   - Start the entire environment"
            echo "  stop    - Stop the environment (preserves data)"
            echo "  cleanup - Completely remove the environment"
            echo "  status  - Check environment status"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 