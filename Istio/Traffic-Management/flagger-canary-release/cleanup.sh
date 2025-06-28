#!/bin/bash

# Cleanup script for Flagger Canary Release demo

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
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

# Default values
NAMESPACE="default"
CLEAN_DEPENDENCIES=false

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -n, --namespace NAMESPACE    Kubernetes namespace to clean (default: default)"
    echo "  -d, --dependencies          Also clean Flagger dependencies (Prometheus, etc.)"
    echo "  -a, --all                   Clean everything including dependencies"
    echo "  -h, --help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                          # Clean demo resources in default namespace"
    echo "  $0 -n canary-demo           # Clean demo resources in canary-demo namespace"
    echo "  $0 -a                       # Clean everything including dependencies"
}

# Function to clean demo resources
clean_demo_resources() {
    local namespace="$1"
    
    echo "🧹 Cleaning demo resources in namespace: $namespace"
    
    # Delete canary (this will also clean up generated resources)
    if kubectl get canary canary-release -n "$namespace" &>/dev/null; then
        print_info "Deleting canary release..."
        kubectl delete canary canary-release -n "$namespace"
        print_success "Canary deleted"
    else
        print_info "No canary found in namespace $namespace"
    fi
    
    # Delete application resources
    print_info "Deleting application resources..."
    
    # Delete deployments
    kubectl delete deployment sample-workload -n "$namespace" --ignore-not-found=true
    kubectl delete deployment movie-frontend -n "$namespace" --ignore-not-found=true
    kubectl delete deployment movie-backend -n "$namespace" --ignore-not-found=true
    
    # Delete services (Flagger-managed services should be cleaned up automatically)
    kubectl delete service sample-workload -n "$namespace" --ignore-not-found=true
    kubectl delete service movie-frontend -n "$namespace" --ignore-not-found=true
    kubectl delete service movie-backend -n "$namespace" --ignore-not-found=true
    
    # Delete networking resources
    kubectl delete gateway istio-gateway -n "$namespace" --ignore-not-found=true
    kubectl delete virtualservice sample-workload -n "$namespace" --ignore-not-found=true
    kubectl delete virtualservice movie-backend -n "$namespace" --ignore-not-found=true
    
    # Delete secrets
    kubectl delete secret tmdb-api-key -n "$namespace" --ignore-not-found=true
    
    # Delete any remaining Flagger-managed resources
    kubectl delete destinationrule sample-workload -n "$namespace" --ignore-not-found=true
    
    print_success "Demo resources cleaned up"
}

# Function to clean dependencies
clean_dependencies() {
    echo "🧹 Cleaning Flagger dependencies..."
    
    # Ask for confirmation
    read -p "This will remove Flagger, Prometheus, and Load Tester. Continue? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_info "Skipping dependency cleanup"
        return 0
    fi
    
    # Remove Flagger Load Tester
    print_info "Removing Flagger Load Tester..."
    kubectl delete namespace test --ignore-not-found=true
    
    # Remove Prometheus
    print_info "Removing Prometheus..."
    kubectl delete -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/prometheus.yaml --ignore-not-found=true
    
    # Remove Flagger
    print_info "Removing Flagger..."
    helm uninstall flagger -n istio-system --ignore-not-found || true
    kubectl delete crd canaries.flagger.app --ignore-not-found=true
    kubectl delete crd metrictemplates.flagger.app --ignore-not-found=true
    kubectl delete crd alertproviders.flagger.app --ignore-not-found=true
    
    print_success "Dependencies cleaned up"
}

# Function to clean custom namespace
clean_custom_namespace() {
    local namespace="$1"
    
    if [[ "$namespace" == "default" ]]; then
        print_info "Not deleting default namespace"
        return 0
    fi
    
    if kubectl get namespace "$namespace" &>/dev/null; then
        read -p "Delete namespace $namespace? This will remove all resources in it. (y/N): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            print_info "Deleting namespace $namespace..."
            kubectl delete namespace "$namespace"
            print_success "Namespace $namespace deleted"
        else
            print_info "Keeping namespace $namespace"
        fi
    else
        print_info "Namespace $namespace does not exist"
    fi
}

# Function to show what will be cleaned
show_cleanup_plan() {
    local namespace="$1"
    local clean_deps="$2"
    
    echo "🔍 Cleanup Plan:"
    echo ""
    echo "In namespace '$namespace':"
    echo "  - Canary: canary-release"
    echo "  - Deployments: sample-workload, movie-frontend, movie-backend"
    echo "  - Services: sample-workload, movie-frontend, movie-backend"
    echo "  - Gateway: istio-gateway"
    echo "  - VirtualServices: sample-workload, movie-backend"
    echo "  - Secrets: tmdb-api-key"
    echo "  - DestinationRules: sample-workload"
    
    if [[ "$namespace" != "default" ]]; then
        echo "  - Option to delete namespace: $namespace"
    fi
    
    if [[ "$clean_deps" == "true" ]]; then
        echo ""
        echo "Dependencies (cluster-wide):"
        echo "  - Flagger operator (istio-system namespace)"
        echo "  - Prometheus (istio-system namespace)"
        echo "  - Flagger Load Tester (test namespace)"
        echo "  - Flagger CRDs"
    fi
    
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -d|--dependencies)
            CLEAN_DEPENDENCIES=true
            shift
            ;;
        -a|--all)
            CLEAN_DEPENDENCIES=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main execution
main() {
    echo "🧹 Flagger Canary Release Demo Cleanup"
    echo ""
    
    # Show cleanup plan
    show_cleanup_plan "$NAMESPACE" "$CLEAN_DEPENDENCIES"
    
    # Ask for confirmation
    read -p "Proceed with cleanup? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_info "Cleanup cancelled"
        exit 0
    fi
    
    echo ""
    
    # Clean demo resources
    clean_demo_resources "$NAMESPACE"
    
    # Clean custom namespace if requested
    if [[ "$NAMESPACE" != "default" ]]; then
        echo ""
        clean_custom_namespace "$NAMESPACE"
    fi
    
    # Clean dependencies if requested
    if [[ "$CLEAN_DEPENDENCIES" == "true" ]]; then
        echo ""
        clean_dependencies
    fi
    
    echo ""
    print_success "Cleanup completed!"
    
    # Show remaining resources
    echo ""
    print_info "Remaining resources:"
    
    if [[ "$NAMESPACE" != "default" ]] && kubectl get namespace "$NAMESPACE" &>/dev/null; then
        echo "Namespace $NAMESPACE still exists with resources:"
        kubectl get all -n "$NAMESPACE" 2>/dev/null || echo "  No resources found"
    fi
    
    if [[ "$CLEAN_DEPENDENCIES" == "false" ]]; then
        echo ""
        print_info "Flagger dependencies are still installed:"
        echo "  - Flagger operator: $(kubectl get deployment flagger -n istio-system &>/dev/null && echo "Present" || echo "Not found")"
        echo "  - Prometheus: $(kubectl get deployment prometheus -n istio-system &>/dev/null && echo "Present" || echo "Not found")"
        echo "  - Load Tester: $(kubectl get deployment flagger-loadtester -n test &>/dev/null && echo "Present" || echo "Not found")"
        echo ""
        print_info "To clean dependencies, run: $0 -d"
    fi
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
