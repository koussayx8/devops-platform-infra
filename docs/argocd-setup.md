# ArgoCD GitOps Setup Guide

This document explains how to set up and use ArgoCD for GitOps deployment of the Ski Station Management Platform.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Developer     │    │   Git Repository │    │   EKS Cluster   │
│                 │    │                 │    │                 │
│   git push      ├───►│  devops-platform├───►│   ArgoCD        │
│                 │    │     -infra      │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                                                       ▼
                       ┌─────────────────────────────────────────────┐
                       │          Kubernetes Applications            │
                       │                                             │
                       │  ┌─────────────┐  ┌─────────────────────┐   │
                       │  │ Ski Station │  │   Monitoring Stack  │   │
                       │  │     App     │  │ (Prometheus/Grafana)│   │
                       │  └─────────────┘  └─────────────────────┘   │
                       └─────────────────────────────────────────────┘
```

## 📁 Project Structure

```
devops-platform-infra/
├── argocd/
│   ├── install/                    # ArgoCD installation manifests
│   │   ├── namespace.yaml
│   │   ├── argocd-install.yaml
│   │   └── argocd-ingress.yaml
│   ├── projects/                   # ArgoCD project definitions
│   │   └── ski-station-project.yaml
│   └── applications/               # Application definitions
│       ├── ski-station-dev.yaml
│       └── monitoring-stack.yaml
├── k8s/                           # Kubernetes manifests
│   ├── base/                      # Base configurations
│   └── overlays/                  # Environment-specific configs
│       ├── dev/
│       ├── staging/
│       └── prod/
└── terraform/                     # Infrastructure as Code
    └── scripts/
        └── setup-argocd.sh       # ArgoCD installation script
```

## 🚀 Installation

### Prerequisites

1. **EKS Cluster**: Running Kubernetes cluster with AWS Load Balancer Controller
2. **kubectl**: Configured to access your EKS cluster
3. **helm**: For managing Helm charts (optional for manual installation)

### Quick Installation

```bash
# Make the script executable
chmod +x terraform/scripts/setup-argocd.sh

# Run the installation script
./terraform/scripts/setup-argocd.sh
```

### Manual Installation

1. **Install ArgoCD**:
   ```bash
   kubectl apply -f argocd/install/namespace.yaml
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

2. **Configure Ingress**:
   ```bash
   kubectl apply -f argocd/install/argocd-ingress.yaml
   ```

3. **Create Project and Applications**:
   ```bash
   kubectl apply -f argocd/projects/ski-station-project.yaml
   kubectl apply -f argocd/applications/
   ```

## 🔐 Access ArgoCD

### Get Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

### Access URL

ArgoCD will be available at: `https://your-alb-hostname/argocd`

**Default Credentials**:
- Username: `admin`
- Password: Retrieved from the secret above

## 📱 Applications

### 1. Monitoring Stack
- **Name**: `monitoring-stack`
- **Purpose**: Deploys Prometheus, Grafana, and AlertManager
- **Namespace**: `monitoring`
- **Source**: Helm chart from prometheus-community
- **Sync Policy**: Automated with prune and self-heal

### 2. Ski Station Development
- **Name**: `ski-station-dev`
- **Purpose**: Deploys the main application (Frontend + API + Database)
- **Namespace**: `ski-station`
- **Source**: Kustomize overlay from `k8s/overlays/dev`
- **Sync Policy**: Automated with prune and self-heal

## 🔄 GitOps Workflow

### Development Workflow

1. **Code Changes**: Developer pushes code to feature branch
2. **CI/CD Pipeline**: Jenkins builds and tests the application
3. **Image Update**: New container image is pushed to registry
4. **Manifest Update**: Jenkins or developer updates image tag in k8s manifests
5. **Git Commit**: Changes are committed to the repository
6. **ArgoCD Sync**: ArgoCD detects changes and syncs to cluster
7. **Deployment**: Application is automatically deployed

### Environment Promotion

```bash
# Promote from dev to staging
git checkout main
git merge feature/new-functionality

# Update staging overlay with new image tag
# Commit changes - ArgoCD will automatically deploy to staging
```

## 🛠️ Operations

### Sync an Application Manually

```bash
# Using ArgoCD CLI
argocd app sync ski-station-dev

# Using kubectl
kubectl patch application ski-station-dev -n argocd --type merge -p '{"operation":{"sync":{"revision":"HEAD"}}}'
```

### Check Application Status

```bash
# List all applications
kubectl get applications -n argocd

# Get detailed status
kubectl describe application ski-station-dev -n argocd
```

### View Application Logs

```bash
# View ArgoCD application controller logs
kubectl logs deployment/argocd-application-controller -n argocd

# View specific pod logs through ArgoCD UI
# Navigate to application → Pod → View Logs
```

### Rollback Application

```bash
# Rollback to previous version
argocd app rollback ski-station-dev

# Or rollback to specific revision
argocd app rollback ski-station-dev --revision 12345
```

## 🔧 Configuration

### Sync Policies

Applications are configured with automated sync policies:

```yaml
syncPolicy:
  automated:
    prune: true        # Remove resources not in git
    selfHeal: true     # Revert manual changes
  syncOptions:
    - CreateNamespace=true
    - ApplyOutOfSyncOnly=true
  retry:
    limit: 5
    backoff:
      duration: 5s
      factor: 2
      maxDuration: 3m
```

### RBAC Configuration

The project includes RBAC roles:
- **Developer**: Can view and sync applications
- **DevOps**: Full access to applications and project settings

### Sync Windows

Production deployments are restricted to business hours:
- **Allow**: 9 AM - 5 PM, Monday-Friday
- **Block**: Outside business hours (automatic syncs)

## 🚨 Monitoring and Alerts

### Health Checks

ArgoCD monitors application health using:
- Kubernetes resource status
- Custom health checks
- Resource hooks

### Notifications

Configure notifications for sync status:
- Slack webhooks
- Email notifications
- PagerDuty integration

## 🔍 Troubleshooting

### Common Issues

1. **Application OutOfSync**:
   ```bash
   # Check diff
   argocd app diff ski-station-dev
   
   # Force sync
   argocd app sync ski-station-dev --force
   ```

2. **Ingress Not Working**:
   ```bash
   # Check ALB controller
   kubectl get pods -n kube-system | grep aws-load-balancer
   
   # Check ingress status
   kubectl get ingress -n argocd
   ```

3. **Permission Errors**:
   ```bash
   # Check project permissions
   kubectl describe appproject ski-station-project -n argocd
   ```

### Debug Commands

```bash
# Get ArgoCD server logs
kubectl logs deployment/argocd-server -n argocd

# Get application controller logs
kubectl logs deployment/argocd-application-controller -n argocd

# Port forward for local access (if ingress fails)
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## 📚 Best Practices

### 1. Repository Structure
- Keep infrastructure and application configs separate
- Use Kustomize for environment-specific configurations
- Version control everything

### 2. Security
- Use RBAC to control access
- Enable signature verification for commits
- Rotate ArgoCD admin password regularly

### 3. Monitoring
- Monitor ArgoCD application health
- Set up alerts for sync failures
- Track deployment metrics

### 4. Backup and Recovery
- Backup ArgoCD configuration
- Document recovery procedures
- Test disaster recovery scenarios

## 🔗 Useful Links

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://www.gitops.tech/)
- [Kustomize Documentation](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)

## 📞 Support

For issues and questions:
1. Check ArgoCD application status in the UI
2. Review application controller logs
3. Consult the troubleshooting section above
4. Contact the DevOps team

---

**Happy GitOpsing! 🚀**