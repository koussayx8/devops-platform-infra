# VPC Module

This Terraform module creates a production-ready VPC with public and private subnets across multiple Availability Zones, designed specifically for EKS cluster deployment.

## 🎯 Overview

The VPC module provisions a complete networking infrastructure with:
- Multi-AZ architecture for high availability
- Separate public and private subnets
- NAT Gateway for private subnet internet access
- VPC Flow Logs for security monitoring
- EKS-specific subnet tags for AWS Load Balancer Controller

## ✨ Features

- ✅ **Custom VPC**: User-defined CIDR block
- ✅ **Multi-AZ Subnets**: Public and private subnets across multiple AZs
- ✅ **Internet Gateway**: Public internet access for public subnets
- ✅ **NAT Gateway**: Private subnet outbound internet access
- ✅ **Route Tables**: Automatic route table configuration
- ✅ **VPC Flow Logs**: Network traffic monitoring via CloudWatch
- ✅ **EKS-Ready Tags**: Automatic Kubernetes subnet tagging
- ✅ **Cost Optimization**: Single NAT Gateway option

## 📊 Architecture

```
┌────────────────────────────────────────────────────┐
│               VPC (10.0.0.0/16)                   │
│                                                    │
│  ┌──────────────────┐    ┌──────────────────┐    │
│  │  Public Subnet   │    │  Public Subnet   │    │
│  │  10.0.1.0/24     │    │  10.0.2.0/24     │    │
│  │  (us-east-1a)    │    │  (us-east-1b)    │    │
│  │                  │    │                  │    │
│  │  ┌─────────┐     │    │                  │    │
│  │  │   IGW   │     │    │                  │    │
│  │  └────┬────┘     │    │                  │    │
│  │       │          │    │                  │    │
│  │  ┌────▼────┐     │    │                  │    │
│  │  │   NAT   │     │    │                  │    │
│  │  │ Gateway │     │    │                  │    │
│  │  └────┬────┘     │    │                  │    │
│  └───────┼──────────┘    └──────────────────┘    │
│          │                                        │
│  ┌───────▼──────────┐    ┌──────────────────┐    │
│  │ Private Subnet   │    │ Private Subnet   │    │
│  │  10.0.10.0/24    │    │  10.0.20.0/24    │    │
│  │  (us-east-1a)    │    │  (us-east-1b)    │    │
│  │                  │    │                  │    │
│  │  [EKS Nodes]     │    │  [EKS Nodes]     │    │
│  └──────────────────┘    └──────────────────┘    │
└────────────────────────────────────────────────────┘
```

## 📝 Usage

### Basic Example

```hcl
module "vpc" {
  source = "./modules/vpc"
  
  environment        = "dev"
  vpc_cidr          = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = true  # Cost optimization for dev/staging
  
  tags = {
    Project     = "devops-platform"
    Owner       = "koussay"
    Environment = "dev"
  }
}
```

### Production Example with High Availability

```hcl
module "vpc" {
  source = "./modules/vpc"
  
  environment        = "prod"
  vpc_cidr          = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = false  # NAT Gateway per AZ for HA
  
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Project     = "devops-platform"
    Owner       = "koussay"
    Environment = "prod"
  }
}
```

## 🔧 Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `environment` | Environment name (dev/staging/prod) | `string` | n/a | yes |
| `vpc_cidr` | CIDR block for VPC | `string` | n/a | yes |
| `availability_zones` | List of availability zones | `list(string)` | n/a | yes |
| `public_subnet_cidrs` | CIDR blocks for public subnets | `list(string)` | n/a | yes |
| `private_subnet_cidrs` | CIDR blocks for private subnets | `list(string)` | n/a | yes |
| `enable_nat_gateway` | Enable NAT Gateway for private subnets | `bool` | `true` | no |
| `single_nat_gateway` | Use single NAT Gateway (cost savings) | `bool` | `true` | no |
| `enable_dns_hostnames` | Enable DNS hostnames in VPC | `bool` | `true` | no |
| `enable_dns_support` | Enable DNS support in VPC | `bool` | `true` | no |
| `tags` | Tags to apply to all resources | `map(string)` | `{}` | no |

## 📤 Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | ID of the VPC |
| `vpc_cidr_block` | CIDR block of the VPC |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `nat_gateway_ids` | List of NAT Gateway IDs |
| `nat_gateway_ips` | List of NAT Gateway public IPs |
| `internet_gateway_id` | ID of the Internet Gateway |
| `public_route_table_id` | ID of the public route table |
| `private_route_table_ids` | List of private route table IDs |

## 🏷️ Resource Tags

The module automatically tags resources with:

### Standard Tags
- `Name`: Resource-specific name
- `Environment`: Environment identifier
- `Type`: Resource type indicator
- All tags from `tags` variable

### EKS-Specific Tags
Subnets are tagged for AWS Load Balancer Controller:

**Public Subnets:**
```hcl
"kubernetes.io/cluster/${environment}-cluster" = "shared"
"kubernetes.io/role/elb" = "1"
```

**Private Subnets:**
```hcl
"kubernetes.io/cluster/${environment}-cluster" = "shared"
"kubernetes.io/role/internal-elb" = "1"
```

## 💰 Cost Optimization

### Single NAT Gateway vs Multiple

**Single NAT Gateway (Recommended for Dev/Staging):**
- **Cost**: ~$32/month
- **Availability**: Single point of failure
- **Use Case**: Non-critical environments

**Multiple NAT Gateways (Recommended for Production):**
- **Cost**: ~$32/month per AZ (e.g., $64 for 2 AZs)
- **Availability**: High availability
- **Use Case**: Production environments

### Enable/Disable NAT Gateway

For testing environments where outbound internet is not needed:

```hcl
enable_nat_gateway = false
```

This saves ~$32+/month but limits private subnet internet access.

## 🔒 Security Features

### VPC Flow Logs

The module creates VPC Flow Logs that capture:
- Accepted traffic
- Rejected traffic
- All traffic

Logs are sent to CloudWatch Logs for analysis and monitoring.

**Use Cases:**
- Security incident investigation
- Network troubleshooting
- Compliance auditing

### Network Isolation

- **Public Subnets**: Accessible from internet via Internet Gateway
- **Private Subnets**: No direct internet access, outbound only via NAT Gateway
- **Recommended**: Place EKS nodes in private subnets for security

## 📚 Technical Details

### IP Allocation

For `10.0.0.0/16` VPC with 4 subnets:

| Subnet | CIDR | IPs | Purpose | AZ |
|--------|------|-----|---------|-----|
| Public 1 | 10.0.1.0/24 | 256 | ALB, NAT Gateway | us-east-1a |
| Public 2 | 10.0.2.0/24 | 256 | Redundancy | us-east-1b |
| Private 1 | 10.0.10.0/24 | 256 | EKS nodes, pods | us-east-1a |
| Private 2 | 10.0.20.0/24 | 256 | EKS nodes, pods | us-east-1b |

**Note**: AWS reserves 5 IPs per subnet, so actual usable IPs = 251 per subnet

### Routing

**Public Subnets:**
```
Destination     Target
10.0.0.0/16     Local
0.0.0.0/0       Internet Gateway
```

**Private Subnets:**
```
Destination     Target
10.0.0.0/16     Local
0.0.0.0/0       NAT Gateway
```

## 🚀 Examples

### Minimal 2-AZ Setup

```hcl
module "vpc" {
  source = "./modules/vpc"
  
  environment        = "dev"
  vpc_cidr          = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = true
  
  tags = { Environment = "dev" }
}
```

### 3-AZ Production Setup

```hcl
module "vpc" {
  source = "./modules/vpc"
  
  environment        = "prod"
  vpc_cidr          = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  public_subnet_cidrs  = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
  private_subnet_cidrs = [
    "10.0.10.0/24",
    "10.0.20.0/24",
    "10.0.30.0/24"
  ]
  
  enable_nat_gateway = true
  single_nat_gateway = false  # One NAT per AZ
  
  tags = {
    Environment = "prod"
    Compliance  = "PCI-DSS"
  }
}
```

## 🔍 Troubleshooting

### Issue: Insufficient IP Addresses

**Symptom**: Pods cannot be scheduled due to no available IPs

**Solution**: Use larger CIDR blocks or add more subnets

```hcl
# Increase subnet size
private_subnet_cidrs = [
  "10.0.0.0/23",   # 512 IPs
  "10.0.2.0/23"    # 512 IPs
]
```

### Issue: NAT Gateway Costs Too High

**Solution**: Use single NAT Gateway for non-production

```hcl
single_nat_gateway = true  # Reduces cost from $64 to $32/month
```

### Issue: VPC Flow Logs Too Verbose

**Solution**: Filter to rejected traffic only

```hcl
traffic_type = "REJECT"  # Only log rejected traffic
```

## 📖 Additional Resources

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [EKS VPC Considerations](https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)

## 📄 License

This module is part of the DevOps Platform Infrastructure project.

---

**Module Version:** 1.0  
**Last Updated:** October 2, 2025  
**Maintainer:** Koussay