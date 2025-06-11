# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Global variables to store command paths
MINIKUBE_CMD=""
KUBECTL_CMD=""
HELM_CMD=""
MVN_CMD=""

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

# Function to check if a command exists and store its path
check_command() {
    local cmd_name="$1"
    local cmd_path

    # Try to find the command's absolute path
    cmd_path=$(type -P "$cmd_name")

    if [ -z "$cmd_path" ]; then
        print_error "$cmd_name is not installed or not found in your system's PATH. Please install it or ensure its directory is in PATH."
        exit 1
    fi

    # Store the found path in a global variable
    case "$cmd_name" in
        "minikube") MINIKUBE_CMD="$cmd_path" ;;
        "kubectl") KUBECTL_CMD="$cmd_path" ;;
        "helm") HELM_CMD="$cmd_path" ;;
        "mvn") MVN_CMD="$cmd_path" ;;
    esac
    print_status "$cmd_name found at: $cmd_path"
}

# Function to wait for a pod to be ready in a namespace
wait_for_pod_ready() {
    local label="$1"
    local namespace="$2"
    local timeout="${3:-120}" # default 2 minutes
    local elapsed=0
    print_status "Waiting for pod with label '$label' in namespace '$namespace' to be ready..."
    while true; do
        status=$("$KUBECTL_CMD" get pods -n "$namespace" -l "$label" -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
        if [ "$status" = "Running" ]; then
            print_status "Pod with label '$label' is running."
            break
        fi
        sleep 3
        elapsed=$((elapsed+3))
        if [ "$elapsed" -ge "$timeout" ]; then
            print_warning "Timeout waiting for pod with label '$label' in namespace '$namespace' to be ready."
            break
        fi
    done
}

# Function to start the environment
start_environment() {
    print_status "Starting Minikube cluster..."
    # Increase disk size to match README.md recommendation for persistent storage
    "$MINIKUBE_CMD" start --cpus=6 --memory=10240m --disk-size=10g

    print_status "Enabling required addons..."
    "$MINIKUBE_CMD" addons enable storage-provisioner
    "$MINIKUBE_CMD" addons enable default-storageclass

    print_status "Creating namespace 'dev-env' if it doesn't exist..."
    # Make namespace creation idempotent
    "$KUBECTL_CMD" get namespace dev-env >/dev/null 2>&1 || "$KUBECTL_CMD" create namespace dev-env

    print_status "Adding Helm repositories..."
    # Add necessary Helm repositories for dependent charts (e.g., Kafka, Airflow)
    "$HELM_CMD" repo add bitnami https://charts.bitnami.com/bitnami || true
    "$HELM_CMD" repo add apache-airflow https://airflow.apache.org/charts || true
    "$HELM_CMD" repo update

    print_status "Deploying streaming platform Helm chart..."
    # Assuming 'streaming-platform' is a sibling directory containing the main Helm chart
    cd streaming-platform || { print_error "Failed to change directory to streaming-platform. Ensure 'streaming-platform' directory exists and contains the Helm chart."; exit 1; }
    "$HELM_CMD" dependency update
    "$HELM_CMD" upgrade --install streaming-platform . -n dev-env --wait
    # Added --wait to wait for all resources to be ready

    cd ..

    print_status "Starting Minikube dashboard (running in background)..."
    "$MINIKUBE_CMD" dashboard --url > /dev/null 2>&1 &

    # Wait for key pods to be ready before port-forwarding
    wait_for_pod_ready "app=kafka-ui" dev-env
    wait_for_pod_ready "component=jobmanager" dev-env
    wait_for_pod_ready "component=webserver" dev-env
    wait_for_pod_ready "component=postgres" dev-env

    print_status "Starting port forwarding for UIs (running in background)..."
    # Start port forwarding in background
    "$KUBECTL_CMD" port-forward svc/kafka-ui 8080:8080 -n dev-env &
    "$KUBECTL_CMD" port-forward svc/flink-jobmanager 8081:8081 -n dev-env &
    "$KUBECTL_CMD" port-forward svc/airflow-webserver 8082:8080 -n dev-env &
    "$KUBECTL_CMD" port-forward svc/airflow-postgres 5432:5432 -n dev-env &
    # Check if 'kafka' service needs external access (e.g., using a NodePort or LoadBalancer for 9094)
    # The default bitnami Kafka chart typically exposes 9092 internally.
    # If 9094 is for external access, ensure it's configured in your Helm chart values for Kafka.
    # For a simple Minikube setup, direct 9092 port-forwarding to kafka-0 might be more common for external clients.
    # "$KUBECTL_CMD" port-forward svc/kafka 9094:9094 -n dev-env & # This assumes a service exposes 9094
    # A more common approach for external Kafka access in Minikube is:
    # "$KUBECTL_CMD" port-forward svc/kafka 9092:9092 -n dev-env & # For internal broker listener
    # Or, if using a loadbalancer/nodeport in chart: minikube service kafka --url
    
    # Store the PID of the last port-forward command, or better, for all
    # For robust management, one might store PIDs in an array or a file.
    # For now, relying on pkill -f "kubectl port-forward" is acceptable for a dev script.

    print_status "Environment is ready!"
    print_status "Access points:"
    echo "- Minikube Dashboard: Run 'minikube dashboard --url' to get the URL if not already printed."
    echo "- Kafka UI: http://localhost:8080"
    echo "- Flink UI: http://localhost:8081"
    echo "- Airflow UI: http://localhost:8082"
    echo "- Postgres (Direct DB Access): localhost:5432"
    echo "- Kafka (Internal Cluster Access): localhost:9092 (if port-forwarded directly)"
    echo -e "${YELLOW}NOTE: The port-forwarding commands run in the background. Use 'pkill -f \"kubectl port-forward\"' to stop them manually.${NC}"
}

# Function to stop the environment
stop_environment() {
    print_status "Stopping port forwarding..."
    pkill -f "kubectl port-forward"

    print_status "Uninstalling Helm release 'streaming-platform'..."
    # Make uninstall idempotent using || true
    "$HELM_CMD" uninstall streaming-platform -n dev-env || true

    print_status "Deleting namespace 'dev-env'..."
    # kubectl delete namespace might hang if pods are stuck. Consider --force --grace-period=0 for dev env.
    "$KUBECTL_CMD" delete namespace dev-env --wait=false || true # Delete in background if stuck

    print_status "Stopping Minikube..."
    "$MINIKUBE_CMD" stop

    print_status "Environment stopped successfully!"
}

# Function to completely clean up
cleanup_environment() {
    print_status "Stopping environment before cleanup..."
    stop_environment

    print_status "Deleting Helm release 'streaming-platform' (if still present)..."
    "$HELM_CMD" uninstall streaming-platform -n dev-env || true

    print_status "Deleting namespace 'dev-env'..."
    "$KUBECTL_CMD" delete namespace dev-env --wait=true || true

    print_status "Waiting for namespace 'dev-env' to terminate..."
    for i in {1..60}; do
        ns_status=$("$KUBECTL_CMD" get ns dev-env --no-headers 2>/dev/null | awk '{print $2}')
        if [ -z "$ns_status" ]; then
            print_status "Namespace 'dev-env' deleted."
            break
        fi
        sleep 2
    done

    print_status "Stopping Minikube (if running)..."
    "$MINIKUBE_CMD" stop || true

    print_status "Deleting Minikube cluster..."
    "$MINIKUBE_CMD" delete || true

    print_status "Killing any lingering port-forward processes..."
    pkill -f "kubectl port-forward" || true

    print_status "Cleanup complete! All resources have been removed."
}

# Function to check environment status
check_status() {
    print_status "Checking environment status..."
    
    echo -e "\nMinikube status:"
    "$MINIKUBE_CMD" status
    
    echo -e "\nNamespace status:"
    "$KUBECTL_CMD" get ns dev-env || echo "Namespace 'dev-env' does not exist."
    
    echo -e "\nPod status in 'dev-env' namespace:"
    "$KUBECTL_CMD" get pods -n dev-env || echo "No pods found in 'dev-env' namespace or namespace does not exist."
    
    echo -e "\nService status in 'dev-env' namespace:"
    "$KUBECTL_CMD" get svc -n dev-env || echo "No services found in 'dev-env' namespace or namespace does not exist."
}

# Main script
main() {
    # Check required commands and get their paths
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