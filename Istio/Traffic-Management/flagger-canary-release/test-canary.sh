#!/bin/bash

# Test script for Flagger Canary Release demo

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
GATEWAY_URL=""
REQUESTS=10
INTERVAL=1

# Help function
show_help() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  test       - Send test requests to the application"
    echo "  monitor    - Monitor canary deployment progress"
    echo "  status     - Show current deployment status"
    echo "  trigger    - Trigger a new canary deployment"
    echo "  rollback   - Manually rollback canary (emergency)"
    echo "  url        - Get application URL"
    echo "  help       - Show this help message"
    echo ""
    echo "Options:"
    echo "  -n, --namespace NAMESPACE    Kubernetes namespace (default: default)"
    echo "  -r, --requests NUM          Number of requests to send (default: 10)"
    echo "  -i, --interval SEC          Interval between requests in seconds (default: 1)"
    echo "  -u, --url URL              Gateway URL (auto-detected if not provided)"
    echo ""
    echo "Examples:"
    echo "  $0 test -r 50 -i 0.5        # Send 50 requests with 0.5s interval"
    echo "  $0 monitor -n canary-demo    # Monitor canary in canary-demo namespace"
    echo "  $0 trigger                   # Trigger new canary with interactive prompts"
    echo "  $0 status                    # Show current status"
}

# Function to get gateway URL
get_gateway_url() {
    if [[ -n "$GATEWAY_URL" ]]; then
        echo "$GATEWAY_URL"
        return
    fi
    
    local ingress_host
    local ingress_port
    
    # Try to get LoadBalancer IP
    ingress_host=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    
    # If no LoadBalancer IP, try hostname
    if [[ -z "$ingress_host" ]]; then
        ingress_host=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    fi
    
    # If still no external IP, try localhost (for development)
    if [[ -z "$ingress_host" ]]; then
        print_warning "No external LoadBalancer found. Trying localhost..."
        ingress_host="localhost"
        ingress_port="8080"
        print_info "Make sure to run: kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80"
    else
        ingress_port=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
    fi
    
    echo "$ingress_host:$ingress_port"
}

# Function to test application with multiple requests
test_application() {
    local url=$(get_gateway_url)
    print_info "Testing application at: http://$url"
    print_info "Sending $REQUESTS requests with ${INTERVAL}s interval..."
    
    local primary_count=0
    local canary_count=0
    local error_count=0
    
    echo ""
    echo "Request | Response Time | Version | Background Color | Status"
    echo "--------|---------------|---------|------------------|-------"
    
    for i in $(seq 1 $REQUESTS); do
        local start_time=$(date +%s.%N)
        local response=$(curl -s -w "%{http_code}" "http://$url" 2>/dev/null || echo "ERROR")
        local end_time=$(date +%s.%N)
        local response_time=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "N/A")
        
        if [[ "$response" == *"ERROR"* ]] || [[ "$response" == *"000"* ]]; then
            echo "$(printf "%7d" $i) | $(printf "%13s" "ERROR") | $(printf "%7s" "N/A") | $(printf "%16s" "N/A") | ERROR"
            ((error_count++))
        else
            local http_code="${response: -3}"
            local body="${response%???}"
            
            # Try to extract version info and background color
            local version="Unknown"
            local bg_color="Unknown"
            
            if echo "$body" | grep -q "v1.0.1"; then
                version="v1.0.1"
                primary_count=$((primary_count + 1))
            elif echo "$body" | grep -q "v2.0.0"; then
                version="v2.0.0"
                canary_count=$((canary_count + 1))
            elif echo "$body" | grep -q "primary"; then
                version="Primary"
                primary_count=$((primary_count + 1))
            elif echo "$body" | grep -q "canary"; then
                version="Canary"
                canary_count=$((canary_count + 1))
            fi
            
            # Try to extract background color
            if echo "$body" | grep -iq "blue"; then
                bg_color="blue"
            elif echo "$body" | grep -iq "green"; then
                bg_color="green"
            elif echo "$body" | grep -iq "red"; then
                bg_color="red"
            fi
            
            local status="OK"
            if [[ "$http_code" != "200" ]]; then
                status="HTTP $http_code"
                ((error_count++))
            fi
            
            echo "$(printf "%7d" $i) | $(printf "%13.3f" "$response_time")s | $(printf "%7s" "$version") | $(printf "%16s" "$bg_color") | $status"
        fi
        
        if [[ $i -lt $REQUESTS ]]; then
            sleep "$INTERVAL"
        fi
    done
    
    echo ""
    echo "=== Summary ==="
    echo "Total requests: $REQUESTS"
    echo "Primary responses: $primary_count ($(echo "scale=1; $primary_count * 100 / $REQUESTS" | bc -l)%)"
    echo "Canary responses: $canary_count ($(echo "scale=1; $canary_count * 100 / $REQUESTS" | bc -l)%)"
    echo "Errors: $error_count ($(echo "scale=1; $error_count * 100 / $REQUESTS" | bc -l)%)"
}

# Function to monitor canary progress
monitor_canary() {
    print_info "Monitoring canary deployment progress..."
    print_info "Press Ctrl+C to stop monitoring"
    
    while true; do
        clear
        echo "=== Canary Status ($(date)) ==="
        
        # Get canary status
        if kubectl get canary canary-release -n "$NAMESPACE" &>/dev/null; then
            kubectl get canary canary-release -n "$NAMESPACE"
            echo ""
            
            # Get detailed status
            local phase=$(kubectl get canary canary-release -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
            local conditions=$(kubectl get canary canary-release -n "$NAMESPACE" -o jsonpath='{.status.conditions}' 2>/dev/null || echo "[]")
            
            echo "Phase: $phase"
            echo ""
            
            # Show traffic distribution
            echo "=== Traffic Distribution ==="
            kubectl get virtualservice sample-workload -n "$NAMESPACE" -o jsonpath='{.spec.http[0].route}' 2>/dev/null | jq . 2>/dev/null || echo "VirtualService not found"
            echo ""
            
        else
            echo "Canary 'canary-release' not found in namespace '$NAMESPACE'"
            echo ""
        fi
        
        # Show pod status
        echo "=== Pod Status ==="
        kubectl get pods -l app=sample-workload -n "$NAMESPACE" 2>/dev/null || echo "No pods found"
        echo ""
        
        # Show recent events
        echo "=== Recent Events ==="
        kubectl get events --field-selector involvedObject.name=canary-release -n "$NAMESPACE" --sort-by='.lastTimestamp' 2>/dev/null | tail -3 || echo "No events found"
        
        sleep 10
    done
}

# Function to show current status
show_status() {
    echo "=== Deployment Status ==="
    
    # Check if canary exists
    if kubectl get canary canary-release -n "$NAMESPACE" &>/dev/null; then
        kubectl describe canary canary-release -n "$NAMESPACE"
    else
        print_warning "Canary 'canary-release' not found in namespace '$NAMESPACE'"
    fi
    
    echo ""
    echo "=== Pod Status ==="
    kubectl get pods -l app=sample-workload -n "$NAMESPACE" 2>/dev/null || echo "No pods found"
    
    echo ""
    echo "=== Service Status ==="
    kubectl get svc -l app=sample-workload -n "$NAMESPACE" 2>/dev/null || echo "No services found"
    
    echo ""
    echo "=== VirtualService Status ==="
    kubectl get virtualservice sample-workload -n "$NAMESPACE" 2>/dev/null || echo "VirtualService not found"
}

# Function to trigger canary deployment
trigger_canary() {
    print_info "Triggering new canary deployment..."
    
    # Get current image
    local current_image=$(kubectl get deployment sample-workload -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "")
    
    if [[ -z "$current_image" ]]; then
        print_error "Could not find deployment 'sample-workload' in namespace '$NAMESPACE'"
        return 1
    fi
    
    print_info "Current image: $current_image"
    
    # Prompt for new configuration
    read -p "Enter new image version (e.g., v2.0.0): " new_version
    read -p "Enter background color (e.g., green, blue, red): " bg_color
    read -p "Enter secondary color (e.g., yellow, white, black): " sec_color
    
    if [[ -z "$new_version" ]]; then
        print_error "Version is required"
        return 1
    fi
    
    bg_color=${bg_color:-green}
    sec_color=${sec_color:-yellow}
    
    print_info "Updating deployment with:"
    print_info "  Image: sayedimran/istio-sample-workload:$new_version"
    print_info "  Background Color: $bg_color"
    print_info "  Secondary Color: $sec_color"
    
    # Update deployment
    kubectl patch deployment sample-workload -n "$NAMESPACE" -p="{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"sample-workload\",\"image\":\"sayedimran/istio-sample-workload:$new_version\",\"env\":[{\"name\":\"BG_COLOR\",\"value\":\"$bg_color\"},{\"name\":\"SECONDARY_COLOR\",\"value\":\"$sec_color\"}]}]}}}}"
    
    print_success "Canary deployment triggered!"
    print_info "Monitor progress with: $0 monitor -n $NAMESPACE"
}

# Function to manually rollback
rollback_canary() {
    print_warning "Manually rolling back canary deployment..."
    
    # This will trigger Flagger to rollback
    kubectl annotate canary canary-release -n "$NAMESPACE" flagger.app/skip-analysis=true --overwrite
    
    print_info "Rollback initiated. Monitor with: $0 monitor -n $NAMESPACE"
}

# Function to show application URL
show_url() {
    local url=$(get_gateway_url)
    print_success "Application URL: http://$url"
    print_info "You can test with: curl http://$url"
    print_info "Or open in browser: http://$url"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -r|--requests)
            REQUESTS="$2"
            shift 2
            ;;
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -u|--url)
            GATEWAY_URL="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        test|monitor|status|trigger|rollback|url|help)
            COMMAND="$1"
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Default command
COMMAND=${COMMAND:-help}

# Execute command
case $COMMAND in
    test)
        test_application
        ;;
    monitor)
        monitor_canary
        ;;
    status)
        show_status
        ;;
    trigger)
        trigger_canary
        ;;
    rollback)
        rollback_canary
        ;;
    url)
        show_url
        ;;
    help)
        show_help
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac
