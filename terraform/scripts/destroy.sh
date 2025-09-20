#!/bin/bash
set -e

echo "⚠️ WARNING: This will destroy all infrastructure!"
read -p "Are you sure you want to continue? (type 'yes'): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Deployment cancelled."
    exit 1
fi

cd "$(dirname "$0")/.."

echo "🗑️ Planning infrastructure destruction..."
terraform plan -destroy -out=tfplan-destroy

echo "💥 Destroying infrastructure..."
terraform apply tfplan-destroy

echo "✅ Infrastructure destroyed successfully!"