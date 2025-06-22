# Traffic Shifting Demo - Deployments Overview

## Namespace
All resources are deployed in the `traffic-shifting-demo` namespace with Istio injection enabled.

## Core Deployments

### 1. Namespace
- **File**: `namespace.yaml`
- **Resource**: Namespace `traffic-shifting-demo`
- **Features**: Istio injection enabled

### 2. Backend Deployments
- **File**: `deployment-v1.yaml`
  - **Resource**: Deployment `movie-backend-v1`
  - **Image**: `sayedimran/istio-sample-app-backend:v1.0.1`
  - **Labels**: `app=movie-backend`, `version=v1`
  
- **File**: `deployment-v2.yaml`  
  - **Resource**: Deployment `movie-backend-v2`
  - **Image**: `sayedimran/istio-sample-app-backend:v1.0.1`
  - **Labels**: `app=movie-backend`, `version=v2`
  - **Environment**: Uses Hollywood data (`DATA_DIR=hollywood-data`)

### 3. Frontend Deployment
- **File**: `frontend.yaml`
  - **Resource**: Deployment `movie-frontend`
  - **Image**: `sayedimran/istio-sample-app-frontend:v1.0.0`
  - **Labels**: `app=movie-frontend`

### 4. Services
- **File**: `service.yaml`
  - **Resource**: Service `movie-backend`
  - **Port**: 8000
  - **Selector**: `app=movie-backend`

- **File**: `frontend.yaml` (includes service)
  - **Resource**: Service `movie-frontend`
  - **Port**: 80
  - **Selector**: `app=movie-frontend`

### 5. Istio Configuration
- **File**: `gateway.yaml`
  - **Resource**: Gateway `istio-gateway`
  - **Hosts**: `*`
  - **Port**: 80 (HTTP)

- **File**: `destination-rule.yaml`
  - **Resource**: DestinationRule `movie-backend`
  - **Subsets**: `v1` and `v2` based on version labels

- **File**: `frontend.yaml` (includes VirtualService)
  - **Resource**: VirtualService `movie-frontend`
  - **Routes**: Frontend traffic routing

### 6. Traffic Splitting Virtual Services
- **File**: `virtual-service-100-0.yaml`
  - **Resource**: VirtualService `movie-backend`
  - **Traffic**: 100% to v1, 0% to v2

- **File**: `virtual-service-80-20.yaml`
  - **Resource**: VirtualService `movie-backend`
  - **Traffic**: 80% to v1, 20% to v2

- **File**: `virtual-service-50-50.yaml`
  - **Resource**: VirtualService `movie-backend`
  - **Traffic**: 50% to v1, 50% to v2

- **File**: `virtual-service-0-100.yaml`
  - **Resource**: VirtualService `movie-backend`
  - **Traffic**: 0% to v1, 100% to v2

### 7. Configuration and Secrets
- **File**: `configs.yaml`
  - **Resource**: ConfigMap `observability-config`
  - **Contains**: Kiali and Grafana configurations

- **Secret**: `tmdb-api-key`
  - **Created by**: `deploy.sh` script
  - **Contains**: TMDB API key for movie data

## Deployment Process

### Prerequisites
1. Kubernetes cluster with Istio installed
2. `kubectl` and `istioctl` commands available
3. TMDB API key (optional, demo key used if not provided)

### Deployment Steps
The `deploy.sh` script handles the complete deployment:

1. **Create Namespace**: Creates `traffic-shifting-demo` namespace with Istio injection
2. **Create Secret**: Creates TMDB API key secret
3. **Deploy Frontend**: Deploys frontend application with service and VirtualService
4. **Deploy Backend**: Deploys both v1 and v2 backend deployments
5. **Deploy Services**: Creates backend service
6. **Deploy Networking**: Creates Gateway and DestinationRule
7. **Deploy Config**: Creates observability ConfigMap
8. **Wait for Ready**: Waits for all deployments to be available

### Traffic Management
Use the deployment script to manage traffic splitting:
- **100% V1**: `./deploy.sh` → Option 2
- **80% V1, 20% V2**: `./deploy.sh` → Option 3  
- **50% V1, 50% V2**: `./deploy.sh` → Option 4
- **100% V2**: `./deploy.sh` → Option 5

### Monitoring
- **Status Check**: `./deploy.sh` → Option 6
- **Get URL**: `./deploy.sh` → Option 7
- **Generate Traffic**: `./deploy.sh` → Option 8
- **Test Splitting**: `./deploy.sh` → Option 9

### Cleanup
- **Full Cleanup**: `./deploy.sh` → Option 10
  - Removes all resources including namespace

## Resource Requirements
- **Frontend**: 512Mi memory, 500m CPU (requests), 1Gi memory, 1 CPU (limits)
- **Backend V1**: 512Mi memory, 500m CPU (requests), 1Gi memory, 1 CPU (limits)  
- **Backend V2**: 512Mi memory, 500m CPU (requests), 1Gi memory, 1 CPU (limits)

## Testing
Test the traffic splitting by:
1. Accessing the frontend URL
2. Making API calls to `/api/movies`
3. Observing logs from different backend versions
4. Using the built-in traffic test pod

All resources are properly configured to run in the `traffic-shifting-demo` namespace with proper isolation and Istio service mesh integration.
