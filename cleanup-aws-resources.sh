#!/bin/bash

# Manual AWS Cleanup Script
# Removes resources conflicting with Terraform deployment
# This is needed when Terraform state is out of sync with AWS

set -e

echo "============================================"
echo "AWS Resource Cleanup Script"
echo "============================================"
echo ""

REGION="ap-south-2"
PROJECT_NAME="demo"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}⚠️  WARNING: This will DELETE AWS resources!${NC}"
echo "Region: $REGION"
echo "Project: $PROJECT_NAME"
echo ""
read -p "Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
  echo "Cancelled."
  exit 1
fi

echo ""
echo -e "${YELLOW}1. Deleting EKS Cluster...${NC}"
aws eks delete-cluster \
  --name ${PROJECT_NAME}-eks \
  --region $REGION 2>/dev/null || echo "  No cluster found"

echo ""
echo -e "${YELLOW}2. Deleting IAM Roles...${NC}"

# Delete role policies first
echo "  - Detaching policies from eks-cluster-role..."
aws iam detach-role-policy \
  --role-name ${PROJECT_NAME}-eks-cluster-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy 2>/dev/null || true

echo "  - Deleting eks-cluster-role..."
aws iam delete-role \
  --role-name ${PROJECT_NAME}-eks-cluster-role 2>/dev/null || echo "    Role not found"

echo "  - Detaching policies from eks-node-role..."
for policy in \
  arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy \
  arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly \
  arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
do
  aws iam detach-role-policy \
    --role-name ${PROJECT_NAME}-eks-node-role \
    --policy-arn $policy 2>/dev/null || true
done

echo "  - Deleting eks-node-role..."
aws iam delete-role \
  --role-name ${PROJECT_NAME}-eks-node-role 2>/dev/null || echo "    Role not found"

echo ""
echo -e "${YELLOW}3. Deleting S3 Bucket...${NC}"
aws s3 rb s3://my-lb-logs-demo-12345 --force 2>/dev/null || echo "  Bucket not found"

echo ""
echo -e "${YELLOW}4. Releasing Elastic IPs...${NC}"
ALLOCATION_IDS=$(aws ec2 describe-addresses \
  --region $REGION \
  --query "Addresses[?Tags[?Key=='Name' && Value=='${PROJECT_NAME}-nat-eip']].AllocationId" \
  --output text 2>/dev/null || echo "")

if [ ! -z "$ALLOCATION_IDS" ]; then
  for alloc_id in $ALLOCATION_IDS; do
    echo "  - Releasing $alloc_id..."
    aws ec2 release-address --allocation-id $alloc_id --region $REGION 2>/dev/null || true
  done
else
  echo "  No Elastic IPs found"
fi

echo ""
echo -e "${YELLOW}5. Deleting VPC and its resources...${NC}"

# Find VPC
VPC_ID=$(aws ec2 describe-vpcs \
  --region $REGION \
  --filters "Name=tag:Name,Values=${PROJECT_NAME}-vpc" \
  --query "Vpcs[0].VpcId" \
  --output text 2>/dev/null || echo "")

if [ "$VPC_ID" != "None" ] && [ ! -z "$VPC_ID" ]; then
  echo "  Found VPC: $VPC_ID"
  
  # Delete Internet Gateway
  echo "  - Deleting Internet Gateways..."
  IGW_IDS=$(aws ec2 describe-internet-gateways \
    --region $REGION \
    --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
    --query "InternetGateways[*].InternetGatewayId" \
    --output text 2>/dev/null || echo "")
  
  for igw_id in $IGW_IDS; do
    aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $VPC_ID --region $REGION 2>/dev/null || true
    aws ec2 delete-internet-gateway --internet-gateway-id $igw_id --region $REGION 2>/dev/null || true
  done
  
  # Delete Subnets
  echo "  - Deleting Subnets..."
  SUBNET_IDS=$(aws ec2 describe-subnets \
    --region $REGION \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "Subnets[*].SubnetId" \
    --output text 2>/dev/null || echo "")
  
  for subnet_id in $SUBNET_IDS; do
    aws ec2 delete-subnet --subnet-id $subnet_id --region $REGION 2>/dev/null || true
  done
  
  # Delete Route Tables
  echo "  - Deleting Route Tables..."
  RT_IDS=$(aws ec2 describe-route-tables \
    --region $REGION \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "RouteTables[?Associations[0].Main != true].RouteTableId" \
    --output text 2>/dev/null || echo "")
  
  for rt_id in $RT_IDS; do
    aws ec2 delete-route-table --route-table-id $rt_id --region $REGION 2>/dev/null || true
  done
  
  # Delete VPC
  echo "  - Deleting VPC..."
  aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION 2>/dev/null || true
else
  echo "  No VPC found"
fi

echo ""
echo -e "${GREEN}✅ Cleanup complete!${NC}"
echo ""
echo "You can now run Terraform apply again:"
echo "  cd env/dev && terraform apply -auto-approve -var-file=terraform.tfvars"
