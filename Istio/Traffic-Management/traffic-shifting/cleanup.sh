#!/bin/bash

# Cleanup script for traffic shifting demo

echo "🧹 Cleaning up Traffic Shifting Demo Resources..."

# Function to cleanup resources
cleanup_resources() {
    echo "Removing Kubernetes resources..."
    
    # Delete frontend resources
    kubectl delete -f frontend.yaml --ignore-not-found=true
    
    # Delete backend resources
    kubectl delete -f deployment-v1.yaml --ignore-not-found=true
    kubectl delete -f deployment-v2.yaml --ignore-not-found=true
    kubectl delete -f service.yaml --ignore-not-found=true
    
    # Delete networking resources
    kubectl delete -f gateway.yaml --ignore-not-found=true
    kubectl delete -f destination-rule.yaml --ignore-not-found=true
    
    # Delete all virtual services
    kubectl delete -f virtual-service-100-0.yaml --ignore-not-found=true
    kubectl delete -f virtual-service-80-20.yaml --ignore-not-found=true
    kubectl delete -f virtual-service-50-50.yaml --ignore-not-found=true
    kubectl delete -f virtual-service-0-100.yaml --ignore-not-found=true
    
    # Delete configuration maps
    kubectl delete -f configs.yaml --ignore-not-found=true
    
    # Delete test pods
    kubectl delete pod traffic-test --ignore-not-found=true
    kubectl delete pod load-test --ignore-not-found=true
    
    # Delete secrets
    kubectl delete secret tmdb-api-key --ignore-not-found=true
    
    echo "✅ All resources cleaned up successfully!"
}

# Function to verify cleanup
verify_cleanup() {
    echo "🔍 Verifying cleanup..."
    
    echo "Checking for remaining resources:"
    echo "- Deployments:"
    kubectl get deployments -l app=movie-backend,app=movie-frontend --no-headers 2>/dev/null | wc -l
    
    echo "- Services:"
    kubectl get services movie-backend,movie-frontend --no-headers 2>/dev/null | wc -l
    
    echo "- VirtualServices:"
    kubectl get virtualservices movie-backend --no-headers 2>/dev/null | wc -l
    
    echo "- DestinationRules:"
    kubectl get destinationrules movie-backend --no-headers 2>/dev/null | wc -l
    
    echo "✅ Cleanup verification completed"
}

# Main execution
case "$1" in
    "verify"|"check")
        verify_cleanup
        ;;
    "force")
        echo "🚨 Force cleanup - removing all resources without confirmation"
        cleanup_resources
        verify_cleanup
        ;;
    *)
        echo "This will remove all traffic shifting demo resources."
        read -p "Are you sure you want to continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cleanup_resources
            verify_cleanup
        else
            echo "Cleanup cancelled."
        fi
        ;;
esac

echo "🏁 Cleanup process completed!"
