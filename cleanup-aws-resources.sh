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

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}⚠️  WARNING: This will DELETE AWS resources!${NC}"
echo "Region: $REGION"
echo "Project: $PROJECT_NAME"
echo ""
read -p "Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
  echo "Cancelled."
  exit 1
fi

safe_delete() {
  echo "  → $1"
  eval "$2" 2>/dev/null || echo "     (not found or already deleted)"
}

# 1. Delete EKS Node Groups FIRST (must delete before cluster)
echo ""
echo -e "${YELLOW}1. Deleting EKS Node Groups...${NC}"
NODE_GROUPS=$(aws eks list-nodegroups --cluster-name ${PROJECT_NAME}-eks --region $REGION --query 'nodegroups[*]' --output text 2>/dev/null || echo "")
for ng in $NODE_GROUPS; do
  safe_delete "Deleting node group: $ng" \
    "aws eks delete-nodegroup --cluster-name ${PROJECT_NAME}-eks --nodegroup-name $ng --region $REGION"
  echo "   Waiting for node group deletion..."
  aws eks wait nodegroup-deleted --cluster-name ${PROJECT_NAME}-eks --nodegroup-name $ng --region $REGION 2>/dev/null || true
done

# 2. Delete EKS Cluster
echo ""
echo -e "${YELLOW}2. Deleting EKS Cluster...${NC}"
safe_delete "Deleting EKS cluster" \
  "aws eks delete-cluster --name ${PROJECT_NAME}-eks --region $REGION"

# 3. Delete IAM Roles (detach policies first)
echo ""
echo -e "${YELLOW}3. Deleting IAM Roles...${NC}"

safe_delete "Detaching policy from eks-cluster-role" \
  "aws iam detach-role-policy --role-name ${PROJECT_NAME}-eks-cluster-role --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
safe_delete "Deleting eks-cluster-role" \
  "aws iam delete-role --role-name ${PROJECT_NAME}-eks-cluster-role"

for policy in \
  arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy \
  arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly \
  arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy; do
  safe_delete "Detaching $policy from eks-node-role" \
    "aws iam detach-role-policy --role-name ${PROJECT_NAME}-eks-node-role --policy-arn $policy"
done
safe_delete "Deleting eks-node-role" \
  "aws iam delete-role --role-name ${PROJECT_NAME}-eks-node-role"

# 4. Delete ALB and Target Groups
echo ""
echo -e "${YELLOW}4. Deleting ALB and Target Groups...${NC}"
ALB_ARN=$(aws elbv2 describe-load-balancers --region $REGION --names "${PROJECT_NAME}-alb" --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || echo "")
if [ "$ALB_ARN" != "None" ] && [ -n "$ALB_ARN" ]; then
  safe_delete "Deleting ALB" \
    "aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN --region $REGION"
  sleep 30
fi

TG_ARN=$(aws elbv2 describe-target-groups --region $REGION --names "${PROJECT_NAME}-tg" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || echo "")
if [ "$TG_ARN" != "None" ] && [ -n "$TG_ARN" ]; then
  safe_delete "Deleting Target Group" \
    "aws elbv2 delete-target-group --target-group-arn $TG_ARN --region $REGION"
fi

# 5. Delete S3 Bucket
echo ""
echo -e "${YELLOW}5. Deleting S3 Bucket...${NC}"
safe_delete "Deleting S3 bucket" \
  "aws s3 rb s3://my-lb-logs-${PROJECT_NAME}-12345 --force"

# 6. Delete Security Group
echo ""
echo -e "${YELLOW}6. Deleting Security Groups...${NC}"
SG_ID=$(aws ec2 describe-security-groups --region $REGION --filters "Name=group-name,Values=allow-my-ip" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || echo "")
if [ "$SG_ID" != "None" ] && [ -n "$SG_ID" ]; then
  safe_delete "Deleting security group $SG_ID" \
    "aws ec2 delete-security-group --group-id $SG_ID --region $REGION"
fi

# 7. Delete VPC and all dependencies
echo ""
echo -e "${YELLOW}7. Deleting VPC and dependencies...${NC}"
VPC_ID=$(aws ec2 describe-vpcs --region $REGION --filters "Name=tag:Name,Values=${PROJECT_NAME}-vpc" --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "")

if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
  echo "  Found VPC: $VPC_ID"
  
  # Delete NAT Gateways
  NAT_IDS=$(aws ec2 describe-nat-gateways --region $REGION --filter Name=vpc-id,Values=$VPC_ID --query 'NatGateways[?State!="deleted"].NatGatewayId' --output text 2>/dev/null || echo "")
  for nat_id in $NAT_IDS; do
    safe_delete "Deleting NAT Gateway: $nat_id" \
      "aws ec2 delete-nat-gateway --nat-gateway-id $nat_id --region $REGION"
  done
  
  if [ -n "$NAT_IDS" ]; then
    echo "  Waiting for NAT gateways to delete (30s)..."
    sleep 30
  fi
  
  # Release Elastic IPs
  EIP_ALLOC_IDS=$(aws ec2 describe-addresses --region $REGION --filters "Name=domain,Values=vpc" --query 'Addresses[*].AllocationId' --output text 2>/dev/null || echo "")
  for eip in $EIP_ALLOC_IDS; do
    safe_delete "Releasing Elastic IP: $eip" \
      "aws ec2 release-address --allocation-id $eip --region $REGION"
  done
  
  # Delete Internet Gateways
  IGW_IDS=$(aws ec2 describe-internet-gateways --region $REGION --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[*].InternetGatewayId' --output text 2>/dev/null || echo "")
  for igw in $IGW_IDS; do
    safe_delete "Detaching/Deleting IGW: $igw" \
      "aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $VPC_ID --region $REGION && aws ec2 delete-internet-gateway --internet-gateway-id $igw --region $REGION"
  done
  
  # Delete Subnets
  SUBNET_IDS=$(aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text 2>/dev/null || echo "")
  for subnet in $SUBNET_IDS; do
    safe_delete "Deleting subnet: $subnet" \
      "aws ec2 delete-subnet --subnet-id $subnet --region $REGION"
  done
  
  # Delete Route Tables
  RT_IDS=$(aws ec2 describe-route-tables --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[?Associations[0].Main != `true`].RouteTableId' --output text 2>/dev/null || echo "")
  for rt in $RT_IDS; do
    safe_delete "Deleting route table: $rt" \
      "aws ec2 delete-route-table --route-table-id $rt --region $REGION"
  done
  
  # Delete VPC
  safe_delete "Deleting VPC: $VPC_ID" \
    "aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION"
else
  echo "  No VPC found"
fi

echo ""
echo -e "${GREEN}✅ Cleanup complete!${NC}"
echo ""
echo "You can now run Terraform apply again:"
echo "  cd env/dev && terraform apply -auto-approve -var-file=terraform.tfvars"
