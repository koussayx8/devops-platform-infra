#!/bin/bash
set -e

echo "🚀 Deploying DevOps Platform Infrastructure..."

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install terraform first."
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

# Navigate to terraform directory
cd "$(dirname "$0")/.."

echo "📋 Initializing Terraform..."
terraform init

echo "🔍 Validating Terraform configuration..."
terraform validate

echo "📊 Planning infrastructure changes..."
terraform plan -out=tfplan

echo "🏗️ Applying infrastructure changes..."
terraform apply tfplan

echo "📤 Displaying outputs..."
terraform output

echo "✅ Infrastructure deployment completed successfully!"