terraform {
  required_version = ">= 1.0"
  
  backend "s3" {
    bucket         = "koussayx8-devops-terraform-state"  # Create this bucket
    key            = "devops-platform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"              # Create this table
    encrypt        = true
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "devops-platform"
      Environment = var.environment
      Owner       = "koussay"
      ManagedBy   = "terraform"
    }
  }
}