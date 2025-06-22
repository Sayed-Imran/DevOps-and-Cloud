# Traffic Shifting Setup Guide

This guide will help you set up and run the traffic shifting demo using Istio service mesh.

## Prerequisites

Before you begin, ensure you have the following installed:

1. **Kubernetes cluster** (v1.20+ recommended)
   - Local: Docker Desktop, minikube, kind, or k3s
   - Cloud: GKE, EKS, AKS, or any managed Kubernetes service

2. **kubectl** configured to connect to your cluster
   ```bash
   kubectl version --client
   ```

3. **Istio** installed on your cluster
   ```bash
   # Download and install Istio
   curl -L https://istio.io/downloadIstio | sh -
   export PATH="$PWD/istio-1.x.x/bin:$PATH"
   
   # Install Istio on your cluster
   istioctl install --set values.defaultRevision=default
   
   # Enable automatic sidecar injection for default namespace
   kubectl label namespace default istio-injection=enabled
   ```

4. **TMDB API Key** (optional but recommended)
   - Sign up at https://www.themoviedb.org/
   - Get your API key from the API settings
   - This enables real movie data instead of dummy data

## Quick Start

1. **Clone the repository** (if not already done)
   ```bash
   git clone <repository-url>
   cd traffic-management/traffic-shifting
   ```

2. **Make scripts executable**
   ```bash
   chmod +x deploy.sh test-traffic.sh cleanup.sh
   ```

3. **Deploy the application**
   ```bash
   ./deploy.sh
   ```
   Follow the interactive menu to:
   - Deploy all resources (option 1)
   - Set initial traffic distribution (options 2-5)

4. **Test traffic distribution**
   ```bash
   ./test-traffic.sh test 100
   ```

## Manual Deployment Steps

If you prefer to deploy manually:

1. **Create secret for TMDB API key**
   ```bash
   kubectl create secret generic tmdb-api-key \
     --from-literal=TMDB_API_KEY="your_api_key_here"
   ```

2. **Deploy frontend**
   ```bash
   kubectl apply -f frontend.yaml
   ```

3. **Deploy backend versions**
   ```bash
   kubectl apply -f deployment-v1.yaml
   kubectl apply -f deployment-v2.yaml
   kubectl apply -f service.yaml
   ```

4. **Setup networking**
   ```bash
   kubectl apply -f gateway.yaml
   kubectl apply -f destination-rule.yaml
   ```

5. **Apply traffic splitting configuration**
   ```bash
   # Start with all traffic to v1
   kubectl apply -f virtual-service-100-0.yaml
   ```

## Traffic Distribution Scenarios

The demo includes several pre-configured traffic distribution scenarios:

### Scenario 1: All traffic to V1 (100%-0%)
```bash
kubectl apply -f virtual-service-100-0.yaml
```

### Scenario 2: Canary deployment (80%-20%)
```bash
kubectl apply -f virtual-service-80-20.yaml
```

### Scenario 3: A/B testing (50%-50%)
```bash
kubectl apply -f virtual-service-50-50.yaml
```

### Scenario 4: Full migration to V2 (0%-100%)
```bash
kubectl apply -f virtual-service-0-100.yaml
```

## Testing and Monitoring

### Test Traffic Distribution
```bash
# Test with 100 requests
./test-traffic.sh test 100

# Monitor real-time traffic
./test-traffic.sh monitor

# Check current configuration
./test-traffic.sh config
```

### Access the Application
```bash
# Get the ingress URL
./deploy.sh
# Choose option 7 to get the access URL

# Or manually get the URL
kubectl -n istio-system get service istio-ingressgateway
```

### Monitor with Istio Tools
```bash
# Install Kiali (if not already installed)
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/kiali.yaml

# Install Grafana (if not already installed)
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/grafana.yaml

# Access Kiali dashboard
istioctl dashboard kiali

# Access Grafana dashboard
istioctl dashboard grafana
```

## Understanding the Components

### Application Architecture
- **Frontend**: React-based UI serving movie catalog
- **Backend V1**: Serves Bollywood movies from TMDB API
- **Backend V2**: Serves Hollywood movies from TMDB API

### Istio Components
- **Gateway**: Configures ingress traffic
- **VirtualService**: Defines traffic routing rules
- **DestinationRule**: Configures load balancing and subsets
- **ServiceEntry**: (if needed) for external service access

### Files Overview
```
traffic-shifting/
├── deployment-v1.yaml        # Backend V1 deployment
├── deployment-v2.yaml        # Backend V2 deployment  
├── service.yaml              # Backend service
├── frontend.yaml             # Frontend deployment and service
├── gateway.yaml              # Istio gateway configuration
├── destination-rule.yaml     # Istio destination rule
├── virtual-service-*.yaml    # Traffic splitting configurations
├── configs.yaml              # ConfigMaps for observability
├── deploy.sh                 # Interactive deployment script
├── test-traffic.sh           # Traffic testing script
├── cleanup.sh                # Resource cleanup script
└── README.md                 # Documentation
```

## Troubleshooting

### Common Issues

1. **Pods not starting**
   ```bash
   kubectl get pods
   kubectl describe pod <pod-name>
   kubectl logs <pod-name>
   ```

2. **Istio sidecar not injected**
   ```bash
   kubectl label namespace default istio-injection=enabled
   kubectl rollout restart deployment/movie-backend-v1
   kubectl rollout restart deployment/movie-backend-v2
   ```

3. **Cannot access ingress**
   ```bash
   # Check ingress gateway status
   kubectl -n istio-system get service istio-ingressgateway
   
   # For local testing, use port-forward
   kubectl -n istio-system port-forward service/istio-ingressgateway 8080:80
   ```

4. **Traffic not splitting as expected**
   ```bash
   # Check virtual service configuration
   kubectl get virtualservice -o yaml
   
   # Verify destination rule
   kubectl get destinationrule -o yaml
   ```

### Debug Commands
```bash
# Check Istio proxy configuration
istioctl proxy-config routes <pod-name>
istioctl proxy-config clusters <pod-name>

# Analyze Istio configuration
istioctl analyze

# Check Envoy access logs
kubectl logs <pod-name> -c istio-proxy
```

## Cleanup

To remove all resources:

```bash
./cleanup.sh
```

Or manually:
```bash
kubectl delete -f .
kubectl delete secret tmdb-api-key
```

## Next Steps

After completing this demo, consider exploring:

1. **Advanced Traffic Management**
   - Fault injection
   - Request timeouts and retries  
   - Circuit breakers

2. **Security Features**
   - mTLS configuration
   - Authorization policies
   - Security scanning

3. **Observability**
   - Distributed tracing with Jaeger
   - Metrics collection with Prometheus
   - Service topology with Kiali

4. **Production Considerations**
   - Multi-cluster deployments
   - GitOps integration
   - Progressive delivery with Flagger/Argo Rollouts
