#!/bin/bash
# ECR Setup Script for python-crud-app
# Run this script in an environment with AWS CLI installed

set -e

ACCOUNT_ID="746552104971"
REGION="ap-south-1"
REPOSITORY_NAME="python-crud-app"
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPOSITORY_NAME}"
LOCAL_IMAGE="jonnamohit/terraform:latest"

echo "=== Step 1: Create ECR Repository ==="
aws ecr create-repository \
  --repository-name ${REPOSITORY_NAME} \
  --region ${REGION} || echo "Repository may already exist"

echo ""
echo "=== Step 2: Login to ECR ==="
aws ecr get-login-password --region ${REGION} \
| docker login --username AWS \
--password-stdin ${ECR_URI}

echo ""
echo "=== Step 3: Tag Your Image ==="
docker tag ${LOCAL_IMAGE} ${ECR_URI}:latest

echo ""
echo "=== Step 4: Push to ECR ==="
docker push ${ECR_URI}:latest

echo ""
echo "=== Success! Image pushed to ECR ==="
echo "ECR URI: ${ECR_URI}:latest"
echo ""
echo "To deploy to EKS with Helm, run:"
echo "helm upgrade --install app-new helm/app-new \\"
echo "  --namespace app-new --create-namespace \\"
echo "  --set image.repository=${ECR_URI} \\"
echo "  --set image.tag=latest \\"
echo "  --wait --timeout 5m"
