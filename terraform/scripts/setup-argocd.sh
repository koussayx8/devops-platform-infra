#!/bin/bash
# ArgoCD Setup Script for AWS EKS
# This script installs ArgoCD and configures GitOps for the Ski Station Platform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ARGOCD_VERSION="2.8.4"
ARGOCD_NAMESPACE="argocd"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo -e "${BLUE}🚀 Starting ArgoCD Installation for Ski Station Platform${NC}"
echo -e "${BLUE}Project Root: ${PROJECT_ROOT}${NC}"

# Function to print status
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed. Please install helm first."
        exit 1
    fi
    
    # Check cluster connectivity
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster. Check your kubeconfig."
        exit 1
    fi
    
    # Check if AWS Load Balancer Controller is installed
    if ! kubectl get deployment aws-load-balancer-controller -n kube-system &> /dev/null; then
        print_warning "AWS Load Balancer Controller not found. ArgoCD ingress may not work properly."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    print_status "Prerequisites check completed ✅"
}

# Install ArgoCD
install_argocd() {
    print_status "Installing ArgoCD..."
    
    # Create namespace
    kubectl apply -f "${PROJECT_ROOT}/argocd/install/namespace.yaml"
    
    # Install ArgoCD using official manifests
    kubectl apply -n ${ARGOCD_NAMESPACE} -f "https://raw.githubusercontent.com/argoproj/argo-cd/v${ARGOCD_VERSION}/manifests/install.yaml"
    
    # Wait for ArgoCD pods to be ready
    print_status "Waiting for ArgoCD components to be ready..."
    kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n ${ARGOCD_NAMESPACE}
    kubectl wait --for=condition=available --timeout=600s deployment/argocd-repo-server -n ${ARGOCD_NAMESPACE}
    kubectl wait --for=condition=available --timeout=600s deployment/argocd-dex-server -n ${ARGOCD_NAMESPACE}
    
    kubectl wait --for=condition=ready --timeout=600s pod -l app.kubernetes.io/name=argocd-application-controller -n ${ARGOCD_NAMESPACE}    
    
    print_status "ArgoCD installation completed ✅"
}

# Configure ArgoCD ingress
configure_ingress() {
    print_status "Configuring ArgoCD ingress..."
    
    # Apply ingress configuration
    kubectl apply -f "${PROJECT_ROOT}/argocd/install/argocd-ingress.yaml"
    
    # Wait for ingress to be ready
    print_status "Waiting for ingress to be ready..."
    sleep 30
    
    # Get ALB hostname
    local alb_hostname=""
    local attempts=0
    while [ -z "$alb_hostname" ] && [ $attempts -lt 30 ]; do
        alb_hostname=$(kubectl get ingress argocd-server-ingress -n ${ARGOCD_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
        if [ -z "$alb_hostname" ]; then
            print_status "Waiting for ALB to be provisioned... (attempt $((attempts + 1))/30)"
            sleep 10
            ((attempts++))
        fi
    done
    
    if [ -n "$alb_hostname" ]; then
        print_status "ArgoCD will be available at: https://${alb_hostname}/argocd"
    else
        print_warning "Could not retrieve ALB hostname. Check ingress status manually."
    fi
}

# Configure ArgoCD projects and applications
configure_argocd_apps() {
    print_status "Configuring ArgoCD projects and applications..."
    
    # Wait a bit more for ArgoCD to be fully ready
    sleep 30
    
    # Apply project configuration
    kubectl apply -f "${PROJECT_ROOT}/argocd/projects/ski-station-project.yaml"
    
    # Apply application configurations
    kubectl apply -f "${PROJECT_ROOT}/argocd/applications/monitoring-stack.yaml"
    kubectl apply -f "${PROJECT_ROOT}/argocd/applications/ski-station-dev.yaml"
    
    print_status "ArgoCD projects and applications configured ✅"
}

# Get ArgoCD initial password
get_argocd_password() {
    print_status "Retrieving ArgoCD admin password..."
    
    local password
    password=$(kubectl -n ${ARGOCD_NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "")
    
    if [ -n "$password" ]; then
        echo -e "${GREEN}==================================${NC}"
        echo -e "${GREEN}🔐 ArgoCD Admin Credentials${NC}"
        echo -e "${GREEN}==================================${NC}"
        echo -e "${GREEN}Username: admin${NC}"
        echo -e "${GREEN}Password: ${password}${NC}"
        echo -e "${GREEN}==================================${NC}"
    else
        print_warning "Could not retrieve admin password. You may need to reset it."
        print_status "To reset password: kubectl -n ${ARGOCD_NAMESPACE} patch secret argocd-secret -p '{\"data\":{\"admin.password\":null,\"admin.passwordMtime\":null}}'"
    fi
}

# Display access information
display_access_info() {
    local alb_hostname
    alb_hostname=$(kubectl get ingress argocd-server-ingress -n ${ARGOCD_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    echo -e "${BLUE}==================================${NC}"
    echo -e "${BLUE}🎉 ArgoCD Installation Complete!${NC}"
    echo -e "${BLUE}==================================${NC}"
    
    if [ -n "$alb_hostname" ]; then
        echo -e "${GREEN}🌐 ArgoCD URL: https://${alb_hostname}/argocd${NC}"
    else
        echo -e "${YELLOW}🌐 ArgoCD URL: Check ingress status for ALB hostname${NC}"
        echo -e "${YELLOW}   Command: kubectl get ingress argocd-server-ingress -n ${ARGOCD_NAMESPACE}${NC}"
    fi
    
    echo -e "${GREEN}👤 Username: admin${NC}"
    echo -e "${GREEN}🔍 To get password: kubectl -n ${ARGOCD_NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d${NC}"
    echo
    echo -e "${BLUE}📱 Applications Deployed:${NC}"
    echo -e "${GREEN}  - monitoring-stack (Prometheus + Grafana)${NC}"
    echo -e "${GREEN}  - ski-station-dev (Development environment)${NC}"
    echo
    echo -e "${BLUE}🔧 Useful Commands:${NC}"
    echo -e "${GREEN}  - View applications: kubectl get applications -n ${ARGOCD_NAMESPACE}${NC}"
    echo -e "${GREEN}  - View ArgoCD status: kubectl get pods -n ${ARGOCD_NAMESPACE}${NC}"
    echo -e "${GREEN}  - Port forward (if ingress fails): kubectl port-forward svc/argocd-server -n ${ARGOCD_NAMESPACE} 8080:443${NC}"
    echo -e "${BLUE}==================================${NC}"
}

# Main installation flow
main() {
    echo -e "${BLUE}Starting ArgoCD installation process...${NC}"
    echo -e "${BLUE}This will install ArgoCD and configure GitOps for your Ski Station Platform${NC}"
    echo
    
    read -p "Continue with installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled."
        exit 0
    fi
    
    check_prerequisites
    install_argocd
    configure_ingress
    configure_argocd_apps
    get_argocd_password
    display_access_info
    
    echo -e "${GREEN}🎊 ArgoCD installation and configuration completed successfully!${NC}"
}

# Handle script interruption
trap 'print_error "Installation interrupted"; exit 1' INT TERM

# Run main function
main "$@"