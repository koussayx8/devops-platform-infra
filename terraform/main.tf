# Local values
locals {
  environment = var.environment
  region      = var.aws_region
  
  # Merge common tags with environment-specific tags
  common_tags = merge(var.common_tags, {
    Environment = var.environment
    Region      = var.aws_region
  })
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  environment        = local.environment
  vpc_cidr          = var.vpc_cidr
  availability_zones = var.availability_zones
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
  
  tags = local.common_tags
}

# Future modules will be added here:
# - Security Groups (modules/security)
# - EKS Cluster (modules/eks)
# - RDS Database (modules/rds)