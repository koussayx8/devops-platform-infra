# 🚀 DevOps Platform Infrastructure

[![Terraform](https://img.shields.io/badge/Terraform-v1.0+-623CE4?logo=terraform)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28-326CE5?logo=kubernetes)](https://kubernetes.io/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-2.8.4-EF7B4D?logo=argo)](https://argo-cd.readthedocs.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazon-aws)](https://aws.amazon.com/eks/)
[![GitOps](https://img.shields.io/badge/GitOps-Enabled-00ADD8)](https://www.gitops.tech/)

> **Production-ready Infrastructure as Code (IaC) for deploying a Ski Station Management Platform on AWS EKS with GitOps using ArgoCD**

This repository contains the complete infrastructure automation for deploying a scalable, secure, and observable cloud-native application platform on AWS using modern DevOps practices.

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Features](#-features)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Project Structure](#-project-structure)
- [Infrastructure Components](#-infrastructure-components)
- [GitOps Workflow](#-gitops-workflow)
- [Configuration](#%EF%B8%8F-configuration)
- [Deployment](#-deployment)
- [Monitoring](#-monitoring)
- [Cost Optimization](#-cost-optimization)
- [Troubleshooting](#-troubleshooting)
- [Documentation](#-documentation)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 Overview

The **DevOps Platform Infrastructure** provides a complete, production-ready infrastructure for deploying and managing a Ski Station Management Platform on AWS. It leverages:

- **Infrastructure as Code (IaC)**: Terraform modules for AWS resources
- **Container Orchestration**: Amazon EKS (Kubernetes)
- **GitOps Deployment**: ArgoCD for continuous delivery
- **Observability**: Prometheus & Grafana monitoring stack
- **Security**: VPC isolation, IAM roles, and security groups
- **Cost Optimization**: Spot instances and configurable scaling

### Application Stack

The platform deploys a three-tier application:
- **Frontend**: Angular/React web application
- **Backend API**: Spring Boot REST API
- **Database**: MySQL 8.0

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud (us-east-1)                    │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    VPC (10.0.0.0/16)                       │ │
│  │                                                            │ │
│  │  ┌──────────────────┐         ┌──────────────────┐       │ │
│  │  │  Public Subnet   │         │  Public Subnet   │       │ │
│  │  │   10.0.1.0/24    │         │   10.0.2.0/24    │       │ │
│  │  │   (us-east-1a)   │         │   (us-east-1b)   │       │ │
│  │  │                  │         │                  │       │ │
│  │  │  ┌───────────┐   │         │                  │       │ │
│  │  │  │    ALB    │   │         │                  │       │ │
│  │  │  │ (Internet │   │         │                  │       │ │
│  │  │  │  Facing)  │   │         │                  │       │ │
│  │  │  └─────┬─────┘   │         │                  │       │ │
│  │  └────────┼─────────┘         └──────────────────┘       │ │
│  │           │                                                │ │
│  │  ┌────────┼─────────┐         ┌──────────────────┐       │ │
│  │  │ Private Subnet   │         │ Private Subnet   │       │ │
│  │  │  10.0.10.0/24    │         │  10.0.20.0/24    │       │ │
│  │  │   (us-east-1a)   │         │   (us-east-1b)   │       │ │
│  │  │                  │         │                  │       │ │
│  │  │  ┌────────────┐  │         │  ┌────────────┐  │       │ │
│  │  │  │ EKS Node   │  │         │  │ EKS Node   │  │       │ │
│  │  │  │  (Spot)    │  │         │  │  (Spot)    │  │       │ │
│  │  │  └────────────┘  │         │  └────────────┘  │       │ │
│  │  │        ▲         │         │        ▲         │       │ │
│  │  │        │         │         │        │         │       │ │
│  │  │  ┌─────┴──────┐  │         │  ┌─────┴──────┐  │       │ │
│  │  │  │ EKS Pods   │  │         │  │ EKS Pods   │  │       │ │
│  │  │  │• Frontend  │  │         │  │• API       │  │       │ │
│  │  │  │• API       │  │         │  │• Database  │  │       │ │
│  │  │  │• Monitoring│  │         │  │• ArgoCD    │  │       │ │
│  │  │  └────────────┘  │         │  └────────────┘  │       │ │
│  │  └──────────────────┘         └──────────────────┘       │ │
│  │                                                            │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    EKS Control Plane                       │ │
│  │                    (Managed by AWS)                        │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘

                         ┌──────────────┐
                         │   GitHub     │
                         │ Repository   │
                         │              │
                         │  GitOps      │
                         │  Manifests   │
                         └──────┬───────┘
                                │
                         ┌──────▼───────┐
                         │   ArgoCD     │
                         │ Continuous   │
                         │  Delivery    │
                         └──────────────┘
```

### Key Components

1. **Networking Layer**: VPC with public/private subnets across 2 AZs
2. **Compute Layer**: EKS cluster with managed node groups (Spot instances)
3. **Application Layer**: Containerized microservices
4. **GitOps Layer**: ArgoCD for automated deployments
5. **Observability Layer**: Prometheus & Grafana monitoring
6. **Security Layer**: IAM roles, Security Groups, IRSA

## ✨ Features

### Infrastructure Features
- ✅ **Multi-AZ Deployment**: High availability across multiple availability zones
- ✅ **Auto-scaling**: Kubernetes HPA and Cluster Autoscaler
- ✅ **Cost-Optimized**: Spot instances for cost reduction (up to 90%)
- ✅ **Secure Networking**: Private subnets, NAT gateways, security groups
- ✅ **IRSA Support**: IAM Roles for Service Accounts (OIDC provider)
- ✅ **VPC Flow Logs**: Network traffic monitoring
- ✅ **Remote State**: S3 backend with DynamoDB state locking

### GitOps Features
- ✅ **Automated Sync**: Auto-sync with prune and self-heal
- ✅ **Multi-Environment**: Dev, Staging, Production environments
- ✅ **Declarative Config**: Everything defined in Git
- ✅ **Rollback Support**: Easy rollback to previous versions
- ✅ **Health Monitoring**: Application health checks
- ✅ **Sync Waves**: Ordered deployment with wave annotations

### Monitoring Features
- ✅ **Prometheus**: Metrics collection and alerting
- ✅ **Grafana**: Visualization dashboards
- ✅ **ServiceMonitor**: Automatic service discovery
- ✅ **Custom Dashboards**: Pre-configured Grafana dashboards
- ✅ **Application Metrics**: Spring Boot Actuator integration

## 🔧 Prerequisites

Before you begin, ensure you have the following tools installed:

### Required Tools

| Tool | Version | Purpose | Installation |
|------|---------|---------|--------------|
| **Terraform** | >= 1.0 | Infrastructure provisioning | [Install Guide](https://developer.hashicorp.com/terraform/downloads) |
| **AWS CLI** | >= 2.0 | AWS operations | [Install Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
| **kubectl** | >= 1.28 | Kubernetes management | [Install Guide](https://kubernetes.io/docs/tasks/tools/) |
| **helm** | >= 3.0 | Kubernetes package manager | [Install Guide](https://helm.sh/docs/intro/install/) |

### AWS Requirements

1. **AWS Account**: Active AWS account with appropriate permissions
2. **AWS Credentials**: Configured via `aws configure` or environment variables
3. **S3 Bucket**: For Terraform state storage (create before deployment)
4. **DynamoDB Table**: For Terraform state locking (create before deployment)
5. **IAM Permissions**: Required permissions:
   - VPC creation and management
   - EKS cluster and node group management
   - IAM role creation
   - EC2 instance management
   - CloudWatch logs

### Terraform Backend Setup

Create the S3 bucket and DynamoDB table for state management:

```bash
# Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket devops-terraform-state \
  --region us-east-1

# Enable versioning on the bucket
aws s3api put-bucket-versioning \
  --bucket devops-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/koussayx8/devops-platform-infra.git
cd devops-platform-infra
```

### 2. Configure Variables

```bash
# Copy the example variables file
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit the variables file with your settings
nano terraform/terraform.tfvars
```

### 3. Deploy Infrastructure

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Review the planned changes
terraform plan

# Apply the infrastructure
terraform apply
```

### 4. Configure kubectl

```bash
# Update kubeconfig to connect to EKS cluster
aws eks update-kubeconfig --region us-east-1 --name dev-cluster

# Verify connection
kubectl get nodes
```

### 5. Install ArgoCD

```bash
# Make the setup script executable
chmod +x terraform/scripts/setup-argocd.sh

# Run ArgoCD installation
./terraform/scripts/setup-argocd.sh
```

### 6. Access Applications

After deployment, retrieve the access URLs:

```bash
# Get ArgoCD URL
kubectl get ingress argocd-server-ingress -n argocd

# Get Application URL
kubectl get ingress ski-station-ingress -n ski-station

# Get Grafana URL
kubectl get ingress grafana-ingress -n monitoring
```

## 📁 Project Structure

```
devops-platform-infra/
├── README.md                          # This file
├── docs/                              # Documentation
│   ├── architecture.md                # Architecture details
│   ├── deployment-guide.md            # Detailed deployment guide
│   ├── argocd-setup.md               # ArgoCD GitOps guide
│   ├── troubleshooting.md            # Troubleshooting guide
│   └── diagrams/                      # Architecture diagrams
│       ├── application-flow.png
│       └── network-architecture.png
│
├── terraform/                         # Infrastructure as Code
│   ├── main.tf                        # Main Terraform configuration
│   ├── variables.tf                   # Variable definitions
│   ├── outputs.tf                     # Output definitions
│   ├── backend.tf                     # Remote state configuration
│   ├── terraform.tfvars.example       # Example variables
│   │
│   ├── modules/                       # Terraform modules
│   │   ├── vpc/                       # VPC module
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   ├── eks/                       # EKS cluster module
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   └── security/                  # Security groups module
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── README.md
│   │
│   └── scripts/                       # Automation scripts
│       ├── deploy.sh                  # Infrastructure deployment
│       ├── destroy.sh                 # Infrastructure cleanup
│       ├── setup-argocd.sh           # ArgoCD installation
│       └── validate.sh               # Configuration validation
│
├── k8s/                              # Kubernetes manifests
│   ├── kustomization.yaml            # Kustomize configuration
│   └── base/                         # Base configurations
│       ├── namespace.yaml            # Namespace definitions
│       ├── deployment.yaml           # Application deployments
│       ├── service.yaml              # Service definitions
│       ├── ingress.yaml              # Ingress configurations
│       ├── configmap.yaml            # ConfigMaps
│       ├── servicemonitor.yaml       # Prometheus ServiceMonitor
│       ├── monitoring-values.yaml    # Monitoring stack config
│       ├── monitoring-ingress.yaml   # Monitoring ingress
│       ├── dashboard-configmap.yaml  # Grafana dashboards
│       └── nginx-configmap.yaml      # Nginx configuration
│
└── argocd/                           # ArgoCD configurations
    ├── install/                      # Installation manifests
    │   ├── namespace.yaml
    │   ├── argocd-install.yaml
    │   └── argocd-ingress.yaml
    ├── projects/                     # ArgoCD projects
    │   └── ski-station-project.yaml
    └── applications/                 # Application definitions
        ├── ski-station-dev.yaml      # Dev environment
        └── monitoring-stack.yaml     # Monitoring stack
```

## 🏭 Infrastructure Components

### 1. VPC Module (`terraform/modules/vpc/`)

Creates a production-ready VPC with:
- **CIDR Block**: 10.0.0.0/16 (65,536 IPs)
- **Public Subnets**: 2 subnets across different AZs
- **Private Subnets**: 2 subnets for EKS nodes
- **Internet Gateway**: For public subnet internet access
- **NAT Gateway**: For private subnet outbound access
- **Route Tables**: Separate for public and private subnets
- **VPC Flow Logs**: Network traffic monitoring

**Key Features**:
- Multi-AZ deployment for high availability
- Cost optimization with single NAT gateway option
- Kubernetes-specific subnet tags for ALB Controller
- VPC peering support

### 2. EKS Module (`terraform/modules/eks/`)

Provisions a fully-managed EKS cluster with:
- **Control Plane**: Managed by AWS (no infrastructure costs)
- **Node Group**: Auto-scaling worker nodes
- **IRSA**: IAM Roles for Service Accounts (OIDC)
- **Logging**: All control plane logs enabled
- **Add-ons**: VPC CNI, kube-proxy, CoreDNS

**Node Configuration**:
- Instance Type: m7i-flex.large (flexible compute)
- Capacity Type: SPOT (up to 90% cost savings)
- Auto-scaling: 1-4 nodes based on demand
- AMI: Amazon Linux 2
- Disk: 20GB GP3 volumes

### 3. Security Module (`terraform/modules/security/`)

Implements security best practices:
- Security groups for cluster and nodes
- IAM roles and policies
- RBAC configurations
- Network policies

### 4. Kubernetes Resources (`k8s/base/`)

Application manifests:
- **Deployments**: Frontend, API, Database
- **Services**: ClusterIP services
- **Ingress**: ALB ingress controller
- **ConfigMaps**: Application configuration
- **ServiceMonitor**: Prometheus metrics

### 5. ArgoCD GitOps (`argocd/`)

GitOps automation:
- **Projects**: Logical grouping of applications
- **Applications**: Application deployment definitions
- **Sync Policies**: Automated sync with self-heal
- **RBAC**: Role-based access control

## 🔄 GitOps Workflow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Developer  │────►│ Git Commit  │────►│   GitHub    │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                                │
                                                │ Webhook/Poll
                                                ▼
                                         ┌─────────────┐
                                         │   ArgoCD    │
                                         │ Monitors    │
                                         │  Changes    │
                                         └──────┬──────┘
                                                │
                         ┌──────────────────────┼──────────────────────┐
                         │                      │                      │
                         ▼                      ▼                      ▼
                  ┌─────────────┐        ┌─────────────┐       ┌─────────────┐
                  │   Detects   │        │   Syncs     │       │   Reports   │
                  │  Drift      │        │  Changes    │       │   Status    │
                  └──────┬──────┘        └──────┬──────┘       └─────────────┘
                         │                      │
                         │                      │
                         ▼                      ▼
                  ┌─────────────┐        ┌─────────────┐
                  │ Self-Heal   │        │  Deploy to  │
                  │  Enabled    │        │     EKS     │
                  └─────────────┘        └─────────────┘
```

### Workflow Steps

1. **Code Change**: Developer commits changes to Git repository
2. **Detection**: ArgoCD detects changes automatically (polling every 3 minutes)
3. **Comparison**: ArgoCD compares desired state (Git) vs actual state (Cluster)
4. **Synchronization**: ArgoCD applies changes to cluster
5. **Health Check**: Validates deployment health status
6. **Self-Heal**: Reverts manual changes (if enabled)
7. **Notification**: Reports sync status to configured channels



## ⚙️ Configuration


## 🚢 Deployment

### Initial Deployment

```bash
# 1. Deploy infrastructure
cd terraform
terraform init
terraform apply

# 2. Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name dev-cluster

# 3. Install AWS Load Balancer Controller
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=dev-cluster

# 4. Install ArgoCD
./terraform/scripts/setup-argocd.sh

# 5. Verify deployment
kubectl get pods -A
kubectl get applications -n argocd
```

### Update Deployment

```bash
# Method 1: GitOps (Recommended)
# Update manifests in k8s/base/
git add .
git commit -m "update: application configuration"
git push
# ArgoCD automatically syncs changes

# Method 2: Manual sync
kubectl patch application ski-station-dev -n argocd \
  --type merge -p '{"operation":{"sync":{"revision":"HEAD"}}}'

# Method 3: ArgoCD CLI
argocd app sync ski-station-dev
```

### Rollback

```bash
# View history
kubectl describe application ski-station-dev -n argocd

# Rollback to previous version
argocd app rollback ski-station-dev

# Rollback to specific revision
argocd app rollback ski-station-dev --revision 12345
```

## 📊 Monitoring

### Access Monitoring Stack

```bash
# Get Grafana URL
kubectl get ingress grafana-ingress -n monitoring

# Get Grafana admin password
kubectl get secret grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 -d

# Port forward for local access
kubectl port-forward -n monitoring svc/grafana 3000:80
```

### Pre-configured Dashboards

1. **Kubernetes Cluster Monitoring**
   - Node CPU, Memory, Disk usage
   - Pod statistics
   - Namespace resource consumption

2. **Application Metrics**
   - HTTP request rates
   - Response times
   - Error rates
   - JVM metrics (for Spring Boot)

3. **ArgoCD Metrics**
   - Application sync status
   - Sync frequency
   - Health status


## 💰 Cost Optimization

### Implemented Strategies

1. **Spot Instances**: Up to 90% savings on compute
   ```hcl
   eks_node_capacity_type = "SPOT"
   ```

2. **Single NAT Gateway**: Reduce NAT costs (dev/staging)
   ```hcl
   single_nat_gateway = true
   ```

3. **Right-sizing**: Appropriate instance types
   ```hcl
   eks_node_instance_types = ["m7i-flex.large"]
   ```

4. **Auto-scaling**: Scale down during low traffic
   ```hcl
   eks_node_min_size = 1
   ```

5. **EBS Optimization**: Smaller disk sizes
   ```hcl
   eks_node_disk_size = 20
   ```

### Estimated Monthly Costs (us-east-1)

| Component | Configuration | Est. Cost |
|-----------|--------------|-----------|
| EKS Control Plane | Managed | $73 |
| Worker Nodes (Spot) | 2x m7i-flex.large | $45 |
| NAT Gateway | Single | $32 |
| ALB | 1 ALB | $22 |
| EBS Volumes | 40GB GP3 | $4 |
| **Total** | **Dev Environment** | **~$176/month** |

> **Note**: Costs vary based on usage, region, and configuration. Use [AWS Pricing Calculator](https://calculator.aws/) for accurate estimates.

### Additional Optimization Tips

- Use S3 for static assets instead of EBS
- Implement pod disruption budgets for graceful shutdowns
- Use Horizontal Pod Autoscaler (HPA) for workloads
- Schedule non-critical workloads during off-peak hours
- Enable AWS Compute Optimizer recommendations

## 🔍 Troubleshooting

### Common Issues

#### 1. Terraform Apply Fails

```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify S3 bucket access
aws s3 ls s3://devops-terraform-state

# Re-initialize Terraform
terraform init -upgrade
```

#### 2. Cannot Connect to EKS Cluster

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name dev-cluster

# Verify connection
kubectl cluster-info
kubectl get nodes

# Check IAM permissions
aws sts get-caller-identity
```

#### 3. ArgoCD Applications OutOfSync

```bash
# Check application status
kubectl get applications -n argocd
kubectl describe application ski-station-dev -n argocd

# View diff
argocd app diff ski-station-dev

# Force sync
argocd app sync ski-station-dev --force
```

#### 4. Pods Not Starting

```bash
# Check pod status
kubectl get pods -n ski-station
kubectl describe pod <pod-name> -n ski-station
kubectl logs <pod-name> -n ski-station

# Check events
kubectl get events -n ski-station --sort-by='.lastTimestamp'

# Check resources
kubectl top nodes
kubectl top pods -n ski-station
```

#### 5. Ingress Not Working

```bash
# Check ALB controller
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check ingress status
kubectl get ingress -n ski-station
kubectl describe ingress ski-station-ingress -n ski-station

# Check ALB in AWS Console
aws elbv2 describe-load-balancers
```

### Debug Commands

```bash
# Get all resources in a namespace
kubectl get all -n ski-station

# Check node status
kubectl describe nodes

# View cluster events
kubectl get events -A --sort-by='.lastTimestamp'

# Check resource usage
kubectl top nodes
kubectl top pods -A

# Export logs
kubectl logs -n ski-station deployment/ski-station-api > api-logs.txt

# Port forward for debugging
kubectl port-forward -n ski-station svc/ski-station-api-service 8089:8089
```

### Getting Help

For additional support:
1. Check [documentation](./docs/)
2. Review [troubleshooting guide](./docs/troubleshooting.md)
3. Check ArgoCD UI for application status
4. Review CloudWatch logs
5. Open an issue on GitHub

## 📚 Documentation

Detailed documentation is available in the `docs/` directory:

- **[Architecture Guide](./docs/architecture.md)**: Detailed architecture and design decisions
- **[Deployment Guide](./docs/deployment-guide.md)**: Step-by-step deployment instructions
- **[ArgoCD Setup](./docs/argocd-setup.md)**: GitOps configuration and workflows
- **[Troubleshooting](./docs/troubleshooting.md)**: Common issues and solutions

### Additional Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Amazon EKS Documentation](https://docs.aws.amazon.com/eks/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit your changes**: `git commit -m 'feat: add amazing feature'`
4. **Push to the branch**: `git push origin feature/amazing-feature`
5. **Open a Pull Request**

### Commit Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `chore:` Maintenance tasks
- `refactor:` Code refactoring
- `test:` Test updates

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Koussay**
- GitHub: [@koussayx8](https://github.com/koussayx8)
- Email: koussay@example.com

## 🙏 Acknowledgments

- AWS for providing the cloud infrastructure
- HashiCorp for Terraform
- ArgoCD team for the GitOps platform
- Kubernetes community
- All contributors

---

<div align="center">
  <p><strong>Built with ❤️ using GitOps principles</strong></p>
  <p>⭐ Star this repository if you find it helpful!</p>
</div>