#!/bin/bash

# Deployment script for the Flagger Canary Release demo

set -e

echo "🚀 Starting Flagger Canary Release Demo Deployment..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    print_status "kubectl is available"
}

# Check if istioctl is available
check_istioctl() {
    if ! command -v istioctl &> /dev/null; then
        print_warning "istioctl is not installed or not in PATH"
        print_info "Please install Istio CLI first: https://istio.io/latest/docs/setup/getting-started/"
        return 1
    fi
    print_status "istioctl is available"
    return 0
}

# Check if Istio control plane is installed
check_istio_installed() {
    if kubectl get namespace istio-system &>/dev/null && kubectl get deployment istiod -n istio-system &>/dev/null; then
        print_status "Istio control plane is installed"
        return 0
    else
        print_warning "Istio control plane is not installed"
        return 1
    fi
}

# Check if Flagger is installed
check_flagger() {
    if kubectl get deployment flagger -n istio-system &>/dev/null; then
        print_status "Flagger is installed"
        return 0
    else
        print_warning "Flagger is not installed"
        return 1
    fi
}

# Check if Prometheus is available
check_prometheus() {
    if kubectl get svc prometheus -n istio-system &>/dev/null; then
        print_status "Prometheus is available"
        return 0
    else
        print_warning "Prometheus is not available"
        return 1
    fi
}

# Install Istio
install_istio() {
    echo "📦 Installing Istio..."
    
    # Check if istioctl is available
    if ! check_istioctl; then
        print_error "istioctl is required to install Istio"
        print_info "Please install istioctl first:"
        print_info "curl -L https://istio.io/downloadIstio | sh -"
        print_info "Then add istioctl to your PATH"
        return 1
    fi
    
    # Install Istio with default configuration
    echo "Installing Istio control plane..."
    if istioctl install -y; then
        print_status "Istio control plane installed successfully"
    else
        print_error "Failed to install Istio control plane"
        return 1
    fi
    
    # Wait for Istio control plane to be ready
    echo "⏳ Waiting for Istio control plane to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/istiod -n istio-system || {
        print_warning "Timeout waiting for istiod deployment, but continuing..."
    }
    
    # Verify installation
    if check_istio_installed; then
        print_status "Istio installation verified successfully"
    else
        print_warning "Istio installation could not be verified"
    fi
}

# Install Flagger
install_flagger() {
    echo "📦 Installing Flagger..."
    
    # Add Flagger Helm repository
    if ! helm repo list | grep -q flagger; then
        echo "Adding Flagger Helm repository..."
        helm repo add flagger https://flagger.app
        helm repo update
    fi
    
    # Install Flagger CRDs
    echo "Installing Flagger CRDs..."
    kubectl apply -f https://raw.githubusercontent.com/fluxcd/flagger/main/artifacts/flagger/crd.yaml
    
    # Install Flagger for Istio
    echo "Installing Flagger operator..."
    helm upgrade -i flagger flagger/flagger \
        --namespace=istio-system \
        --set crd.create=false \
        --set meshProvider=istio \
        --set metricsServer=http://prometheus:9090
    
    print_status "Flagger installed successfully"
}

# Install Flagger Load Tester
install_loadtester() {
    echo "📦 Installing Flagger Load Tester..."
    
    
    # Install load tester
    helm upgrade -i flagger-loadtester flagger/loadtester \
        --namespace=istio-system \
        --set cmd.timeout=1h \
        --set cmd.namespaceRegexp=''
    
    print_status "Flagger Load Tester installed successfully"
}

# Install Prometheus
install_prometheus() {
    echo "📦 Installing Prometheus..."
    kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/prometheus.yaml
    
    print_status "Prometheus installed successfully"
}

# Function to check if a namespace has Istio injection enabled
check_istio_injection() {
    local namespace=${1:-default}
    if kubectl get namespace "$namespace" -o jsonpath='{.metadata.labels.istio-injection}' 2>/dev/null | grep -q "enabled"; then
        print_status "Istio injection is enabled for namespace: $namespace"
        return 0
    else
        print_warning "Istio injection is not enabled for namespace: $namespace"
        return 1
    fi
}

# Function to enable Istio injection
enable_istio_injection() {
    local namespace=${1:-default}
    kubectl label namespace "$namespace" istio-injection=enabled --overwrite
    print_status "Enabled Istio injection for namespace: $namespace"
}

# Function to create namespace if it doesn't exist
create_namespace() {
    local namespace=${1:-canary-demo}
    if kubectl get namespace "$namespace" &>/dev/null; then
        print_status "Namespace $namespace already exists"
    else
        echo "📦 Creating namespace $namespace..."
        kubectl create namespace "$namespace"
        print_status "Created namespace $namespace"
    fi
    
    # Enable Istio injection
    if ! check_istio_injection "$namespace"; then
        enable_istio_injection "$namespace"
    fi
}

# Function to create TMDB API key secret
create_secret() {
    local namespace=${1:-default}
    
    # Check if namespace exists first
    if ! kubectl get namespace "$namespace" &>/dev/null; then
        print_warning "Namespace doesn't exist, secret will be created after namespace creation"
        return 0
    fi
    
    if kubectl get secret tmdb-api-key -n "$namespace" &>/dev/null; then
        print_status "TMDB API key secret already exists"
    else
        read -p "Enter your TMDB API key (or press Enter to use a dummy key): " api_key
        api_key=${api_key:-"dummy_api_key_for_demo"}
        kubectl create secret generic tmdb-api-key \
            --from-literal=TMDB_API_KEY="$api_key" \
            -n "$namespace"
        print_status "Created TMDB API key secret"
    fi
}

# Function to deploy initial resources
deploy_initial_resources() {
    local namespace=${1:-default}
    
    echo "📦 Deploying initial application resources..."
    
    # Apply namespace labels if using default
    if [[ "$namespace" == "default" ]]; then
        enable_istio_injection "default"
    fi
    
    # Deploy sample workload
    if [[ "$namespace" != "default" ]]; then
        # Update namespace in deployment files
        sed "s/namespace: .*/namespace: $namespace/" deploy.yaml | kubectl apply -f -
        sed "s/namespace: .*/namespace: $namespace/" frontend.yaml | kubectl apply -f -
        sed "s/namespace: .*/namespace: $namespace/" gateway.yaml | kubectl apply -f -
    else
        kubectl apply -f backend.yaml
        kubectl apply -f frontend.yaml
        kubectl apply -f gateway.yaml
    fi
    
    print_status "Initial resources deployed"
}

# Function to initialize Flagger canary
initialize_canary() {
    local namespace=${1:-default}
    
    echo "📦 Initializing Flagger canary..."
    
    
    # Apply canary configuration
    if [[ "$namespace" != "default" ]]; then
        sed "s/namespace: .*/namespace: $namespace/" canary.yaml | kubectl apply -f -
    else
        kubectl apply -f canary.yaml
    fi
        
    print_status "Flagger canary initialized successfully"
}

# Function to trigger canary release
trigger_canary_release() {
    local namespace=${1:-default}
    local new_version=${2:-v2.0.0}
    local new_bg_color=${3:-green}
    local new_secondary_color=${4:-yellow}
    
    echo "🚀 Triggering canary release..."
    print_info "New version: $new_version"
    print_info "Background color: $new_bg_color"
    print_info "Secondary color: $new_secondary_color"
    
    # Update deployment to trigger canary
    kubectl patch deployment sample-workload -n "$namespace" -p="{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"sample-workload\",\"image\":\"sayedimran/istio-sample-workload:$new_version\",\"env\":[{\"name\":\"BG_COLOR\",\"value\":\"$new_bg_color\"},{\"name\":\"SECONDARY_COLOR\",\"value\":\"$new_secondary_color\"}]}]}}}}"
    
    print_status "Canary release triggered!"
    print_info "Monitor progress with: kubectl get canary canary-release -n $namespace -w"
}

# Function to monitor canary progress
monitor_canary() {
    local namespace=${1:-default}
    
    echo "📊 Monitoring canary progress..."
    echo "Press Ctrl+C to stop monitoring"
    
    while true; do
        clear
        echo "=== Canary Status ==="
        kubectl get canary canary-release -n "$namespace" 2>/dev/null || echo "Canary not found"
        
        echo ""
        echo "=== Pod Status ==="
        kubectl get pods -l app=sample-workload -n "$namespace" 2>/dev/null || echo "No pods found"
        
        echo ""
        echo "=== Recent Events ==="
        kubectl get events --field-selector involvedObject.name=canary-release -n "$namespace" --sort-by='.lastTimestamp' | tail -5 2>/dev/null || echo "No events found"
        
        echo ""
        echo "=== VirtualService Configuration ==="
        kubectl get virtualservice sample-workload -n "$namespace" -o jsonpath='{.spec.http[0].route}' 2>/dev/null | jq . 2>/dev/null || echo "VirtualService not found or jq not available"
        
        sleep 10
    done
}

# Function to get application URL
get_app_url() {
    echo "🌐 Getting application URL..."
    
    local ingress_host
    local ingress_port
    
    # Try to get LoadBalancer IP
    ingress_host=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    
    # If no LoadBalancer IP, try hostname
    if [[ -z "$ingress_host" ]]; then
        ingress_host=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    fi
    
    # If still no external IP, use port-forward
    if [[ -z "$ingress_host" ]]; then
        print_warning "No external LoadBalancer found. Use port-forward to access the application:"
        print_info "kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80"
        print_info "Then access: http://localhost:8080"
        return 0
    fi
    
    ingress_port=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
    
    local gateway_url="$ingress_host:$ingress_port"
    
    print_status "Application URL: http://$gateway_url"
    print_info "You can also test with: curl http://$gateway_url"
}

# Function to check installation prerequisites
check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    check_kubectl
    
    local missing_components=()
    
    # Check istioctl availability
    if ! check_istioctl; then
        missing_components+=("istioctl")
    fi
    
    # Check Istio installation
    if ! check_istio_installed; then
        missing_components+=("istio")
    fi
    
    if ! check_flagger; then
        missing_components+=("flagger")
    fi
    
    if ! check_prometheus; then
        missing_components+=("prometheus")
    fi
    
    if ! kubectl get deployment flagger-loadtester -n istio-system &>/dev/null; then
        missing_components+=("loadtester")
        print_warning "Flagger Load Tester is not installed"
    else
        print_status "Flagger Load Tester is available"
    fi
    
    if [[ ${#missing_components[@]} -gt 0 ]]; then
        print_warning "Missing components: ${missing_components[*]}"
        return 1
    else
        print_status "All prerequisites are satisfied"
        return 0
    fi
}

# Function to install missing components
install_dependencies() {
    echo "📦 Installing missing dependencies..."
    
    # Check and install Istio first (required for other components)
    if ! check_istio_installed; then
        if check_istioctl; then
            install_istio
        else
            print_error "istioctl is required but not installed"
            print_info "Please install istioctl first:"
            print_info "curl -L https://istio.io/downloadIstio | sh -"
            print_info "Then add istioctl to your PATH and run this script again"
            return 1
        fi
    fi
    
    if ! check_prometheus; then
        install_prometheus
    fi
    
    if ! check_flagger; then
        install_flagger
    fi
    
    if ! kubectl get deployment flagger-loadtester -n istio-system &>/dev/null; then
        install_loadtester
    fi
    
    print_status "All dependencies installed"
}

# Function to cleanup resources
cleanup() {
    local namespace=${1:-default}
    
    echo "🧹 Cleaning up resources..."
    
    # Delete canary (this will also clean up generated resources)
    kubectl delete canary canary-release -n "$namespace" --ignore-not-found=true
    
    # Delete application resources
    kubectl delete -f backend.yaml --ignore-not-found=true
    kubectl delete -f frontend.yaml --ignore-not-found=true
    kubectl delete -f gateway.yaml --ignore-not-found=true
    
    # Delete secrets
    kubectl delete secret tmdb-api-key -n "$namespace" --ignore-not-found=true
    
    # If using custom namespace, delete it
    if [[ "$namespace" != "default" ]]; then
        read -p "Delete namespace $namespace? (y/N): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            kubectl delete namespace "$namespace" --ignore-not-found=true
        fi
    fi
    
    print_status "Cleanup completed"
}

# Main menu function
show_menu() {
    echo ""
    echo "=== Flagger Canary Release Demo ==="
    echo "1. Check Prerequisites"
    echo "2. Install Istio"
    echo "3. Install Missing Dependencies"
    echo "4. Deploy Application (with default namespace)"
    echo "5. Deploy Application (with custom namespace)"
    echo "6. Trigger Canary Release"
    echo "7. Monitor Canary Progress"
    echo "8. Get Application URL"
    echo "9. Cleanup Resources"
    echo "10. Exit"
    echo ""
}

# Main execution
main() {
    local namespace="default"
    
    while true; do
        show_menu
        read -p "Choose an option (1-9): " choice
        
        case $choice in
            1)
                check_prerequisites
                ;;
            2)
                if check_istioctl; then
                    install_istio
                else
                    print_error "istioctl is required to install Istio"
                    print_info "Please install istioctl first:"
                    print_info "curl -L https://istio.io/downloadIstio | sh -"
                    print_info "Then add istioctl to your PATH"
                fi
                ;;
            3)
                install_dependencies
                ;;
            4)
                namespace="default"
                if ! check_prerequisites; then
                    print_warning "Prerequisites not met. Install dependencies first (option 3)"
                    continue
                fi
                
                create_secret "$namespace"
                deploy_initial_resources "$namespace"
                initialize_canary "$namespace"
                get_app_url
                ;;
            5)
                read -p "Enter namespace name: " custom_namespace
                namespace="$custom_namespace"
                
                if ! check_prerequisites; then
                    print_warning "Prerequisites not met. Install dependencies first (option 3)"
                    continue
                fi
                
                create_namespace "$namespace"
                create_secret "$namespace"
                deploy_initial_resources "$namespace"
                initialize_canary "$namespace"
                get_app_url
                ;;
            6)
                read -p "Enter new image version (default: v2.0.0): " version
                read -p "Enter background color (default: green): " bg_color
                read -p "Enter secondary color (default: yellow): " sec_color
                
                version=${version:-v2.0.0}
                bg_color=${bg_color:-green}
                sec_color=${sec_color:-yellow}
                
                trigger_canary_release "$namespace" "$version" "$bg_color" "$sec_color"
                ;;
            7)
                monitor_canary "$namespace"
                ;;
            8)
                get_app_url
                ;;
            9)
                cleanup "$namespace"
                ;;
            10)
                echo "👋 Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please choose 1-10."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
