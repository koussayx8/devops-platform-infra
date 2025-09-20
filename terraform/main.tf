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

# EKS Cluster Module
module "eks" {
  source = "./modules/eks"
  
  cluster_name       = "${local.environment}-cluster"
  cluster_version    = var.eks_cluster_version
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  private_subnet_ids = module.vpc.private_subnet_ids
  
  node_group_config = {
    instance_types = var.eks_node_instance_types
    capacity_type  = var.eks_node_capacity_type
    disk_size      = var.eks_node_disk_size
    ami_type       = "AL2_x86_64"
    desired_size   = var.eks_node_desired_size
    max_size       = var.eks_node_max_size
    min_size       = var.eks_node_min_size
  }
  
  endpoint_private_access = true
  endpoint_public_access  = true
  
  tags = local.common_tags
  
  depends_on = [module.vpc]
}