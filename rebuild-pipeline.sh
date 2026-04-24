#!/bin/bash

# Terraform Destroy & Rebuild Pipeline
# This script destroys all infrastructure and rebuilds it fresh

set -e

ENVIRONMENT="dev"
TF_PATH="./env/$ENVIRONMENT"

echo "================================"
echo "Terraform Destroy & Rebuild"
echo "================================"
echo ""

# Change to terraform directory
cd "$TF_PATH"

echo "📋 Current working directory: $(pwd)"
echo ""

# Step 1: Terraform Destroy
echo "🗑️  Destroying existing infrastructure..."
terraform destroy -auto-approve

echo ""
echo "✅ Infrastructure destroyed successfully!"
echo ""

# Step 2: Clean terraform cache (optional but recommended)
echo "🧹 Cleaning terraform cache..."
rm -rf .terraform.lock.hcl
rm -rf .terraform/

echo ""
echo "🔄 Re-initializing terraform..."
terraform init

echo ""
echo "📦 Creating new infrastructure..."
terraform apply -auto-approve

echo ""
echo "✅ Pipeline rebuilt successfully!"
echo ""
echo "================================"
terraform output
echo "================================"
