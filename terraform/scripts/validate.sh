#!/bin/bash
set -e

cd "$(dirname "$0")/.."

echo "🔍 Validating Terraform configuration..."
terraform validate

echo "🎯 Formatting Terraform files..."
terraform fmt -recursive

echo "✅ Validation completed successfully!"