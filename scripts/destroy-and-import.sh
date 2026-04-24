#!/bin/bash

# Comprehensive Destroy & Import Script
# Handles resources that exist in AWS but not in Terraform state
# Usage: ./scripts/destroy-and-import.sh [dev|staging|prod]

set -e

ENVIRONMENT="${1:-dev}"
TF_PATH="env/$ENVIRONMENT"
REGION="ap-south-2"
PROJECT_NAME="demo"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

echo "============================================"
echo "Terraform Destroy & Import Helper"
echo "============================================"
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo ""

cd "$TF_PATH" || { log_error "Directory $TF_PATH not found"; exit 1; }
log_info "Working in: $(pwd)"

# Step 1: Terraform Init
echo ""
log_info "Step 1: Initializing Terraform..."
terraform init

# Step 2: Discover and Import Existing Resources
echo ""
log_info "Step 2: Discovering existing AWS resources..."

import_resource() {
  local resource_address="$1"
  local resource_id="$2"
  
  if [ -z "$resource_id" ] || [ "$resource_id" = "None" ]; then
    log_warn "Resource $resource_address not found in AWS, skipping import"
    return
  fi
  
  log_info "Importing $resource_address (ID: $resource_id)..."
  if terraform import -var-file=terraform.tfvars "$resource_address" "$resource_id" 2>/dev/null; then
    log_success "Imported $resource_address"
  else
    log_warn "Failed to import $resource_address (may already be in state)"
  fi
}

# Discover VPC
VPC_ID=$(aws ec2 describe-vpcs --region $REGION --filters "Name=tag:Name,Values=${PROJECT_NAME}-vpc" --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "")
if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
  log_info "Found VPC: $VPC_ID"
  import_resource "module.vpc.aws_vpc.main" "$VPC_ID"
  
  # Import IGW
  IGW_ID=$(aws ec2 describe-internet-gateways --region $REGION --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text 2>/dev/null || echo "")
  [ "$IGW_ID" != "None" ] && import_resource "module.vpc.aws_internet_gateway.igw" "$IGW_ID"
  
  # Import Subnets
  PUBLIC_SUBNET=$(aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Type,Values=Public" --query 'Subnets[0].SubnetId' --output text 2>/dev/null || echo "")
  [ "$PUBLIC_SUBNET" != "None" ] && import_resource "module.vpc.aws_subnet.public1" "$PUBLIC_SUBNET"
  
  PRIVATE_SUBNET1=$(aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=${PROJECT_NAME}-private-subnet-*a" --query 'Subnets[0].SubnetId' --output text 2>/dev/null || echo "")
  [ "$PRIVATE_SUBNET1" != "None" ] && import_resource "module.vpc.aws_subnet.private1" "$PRIVATE_SUBNET1"
  
  PRIVATE_SUBNET2=$(aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=${PROJECT_NAME}-private-subnet-*b" --query 'Subnets[0].SubnetId' --output text 2>/dev/null || echo "")
  [ "$PRIVATE_SUBNET2" != "None" ] && import_resource "module.vpc.aws_subnet.private2" "$PRIVATE_SUBNET2"
  
  # Import NAT Gateway
  NAT_GW_ID=$(aws ec2 describe-nat-gateways --region $REGION --filter Name=vpc-id,Values=$VPC_ID --query 'NatGateways[?State!="deleted"].NatGatewayId' --output text 2>/dev/null || echo "")
  [ "$NAT_GW_ID" != "None" ] && import_resource "module.vpc.aws_nat_gateway.nat" "$NAT_GW_ID"
  
  # Import EIP
  EIP_ALLOC_ID=$(aws ec2 describe-addresses --region $REGION --filters "Name=domain,Values=vpc" --query 'Addresses[0].AllocationId' --output text 2>/dev/null || echo "")
  [ "$EIP_ALLOC_ID" != "None" ] && import_resource "module.vpc.aws_eip.nat" "$EIP_ALLOC_ID"
fi

# Discover EKS Cluster
CLUSTER_NAME="${PROJECT_NAME}-eks"
CLUSTER_EXISTS=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.name' --output text 2>/dev/null || echo "")
if [ "$CLUSTER_EXISTS" != "None" ] && [ -n "$CLUSTER_EXISTS" ]; then
  log_info "Found EKS Cluster: $CLUSTER_NAME"
  
  # Import IAM Roles
  EKS_ROLE_ARN=$(aws iam get-role --role-name "${PROJECT_NAME}-eks-cluster-role" --query 'Role.Arn' --output text 2>/dev/null || echo "")
  [ "$EKS_ROLE_ARN" != "None" ] && import_resource "module.eks.aws_iam_role.eks_role" "${PROJECT_NAME}-eks-cluster-role"
  
  NODE_ROLE_ARN=$(aws iam get-role --role-name "${PROJECT_NAME}-eks-node-role" --query 'Role.Arn' --output text 2>/dev/null || echo "")
  [ "$NODE_ROLE_ARN" != "None" ] && import_resource "module.eks.aws_iam_role.node_role" "${PROJECT_NAME}-eks-node-role"
  
  # Import EKS Cluster
  import_resource "module.eks.aws_eks_cluster.eks" "$CLUSTER_NAME"
  
  # Import Node Group
  NODE_GROUP=$(aws eks list-nodegroups --cluster-name $CLUSTER_NAME --region $REGION --query 'nodegroups[0]' --output text 2>/dev/null || echo "")
  if [ "$NODE_GROUP" != "None" ] && [ -n "$NODE_GROUP" ]; then
    import_resource "module.eks.aws_eks_node_group.nodes" "${CLUSTER_NAME}:${NODE_GROUP}"
  fi
fi

# Discover S3 Bucket
S3_BUCKET="my-lb-logs-${PROJECT_NAME}-12345"
if aws s3api head-bucket --bucket $S3_BUCKET 2>/dev/null; then
  log_info "Found S3 Bucket: $S3_BUCKET"
  import_resource "module.s3.aws_s3_bucket.lb_logs" "$S3_BUCKET"
fi

# Discover Security Group
SG_ID=$(aws ec2 describe-security-groups --region $REGION --filters "Name=group-name,Values=allow-my-ip" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || echo "")
if [ "$SG_ID" != "None" ] && [ -n "$SG_ID" ]; then
  log_info "Found Security Group: $SG_ID"
  import_resource "module.security.aws_security_group.allow_ip" "$SG_ID"
fi

# Discover ALB
ALB_ARN=$(aws elbv2 describe-load-balancers --region $REGION --names "${PROJECT_NAME}-alb" --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || echo "")
if [ "$ALB_ARN" != "None" ] && [ -n "$ALB_ARN" ]; then
  log_info "Found ALB: ${PROJECT_NAME}-alb"
  import_resource "module.alb.aws_lb.main" "$ALB_ARN"
  
  TG_ARN=$(aws elbv2 describe-target-groups --region $REGION --names "${PROJECT_NAME}-tg" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || echo "")
  [ "$TG_ARN" != "None" ] && import_resource "module.alb.aws_lb_target_group.app" "$TG_ARN"
fi

# Step 3: Run Terraform Destroy
echo ""
log_info "Step 3: Running Terraform destroy..."
if terraform destroy -auto-approve -var-file=terraform.tfvars; then
  log_success "Terraform destroy completed successfully"
else
  log_warn "Terraform destroy had issues, but continuing..."
fi

# Step 4: Clean State Files
echo ""
log_info "Step 4: Cleaning state files..."
rm -f terraform.tfstate terraform.tfstate.backup
log_success "State files removed"

# Step 5: Verify Cleanup
echo ""
log_info "Step 5: Verifying cleanup..."

VERIFY_ISSUES=0

# Check VPC
REMAINING_VPC=$(aws ec2 describe-vpcs --region $REGION --filters "Name=tag:Name,Values=${PROJECT_NAME}-vpc" --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "None")
if [ "$REMAINING_VPC" != "None" ] && [ -n "$REMAINING_VPC" ]; then
  log_error "VPC still exists: $REMAINING_VPC"
  VERIFY_ISSUES=$((VERIFY_ISSUES + 1))
else
  log_success "VPC cleaned up"
fi

# Check IAM Roles
for role in "${PROJECT_NAME}-eks-cluster-role" "${PROJECT_NAME}-eks-node-role"; do
  if aws iam get-role --role-name "$role" >/dev/null 2>&1; then
    log_error "IAM Role still exists: $role"
    VERIFY_ISSUES=$((VERIFY_ISSUES + 1))
  else
    log_success "IAM Role cleaned up: $role"
  fi
done

# Check S3
if aws s3api head-bucket --bucket $S3_BUCKET >/dev/null 2>&1; then
  log_error "S3 Bucket still exists: $S3_BUCKET"
  VERIFY_ISSUES=$((VERIFY_ISSUES + 1))
else
  log_success "S3 Bucket cleaned up"
fi

echo ""
if [ $VERIFY_ISSUES -eq 0 ]; then
  log_success "All resources cleaned up successfully!"
  echo ""
  echo "You can now run:"
  echo "  terraform apply -auto-approve -var-file=terraform.tfvars"
else
  log_error "$VERIFY_ISSUES resource(s) still exist. Run cleanup script:"
  echo "  ./cleanup-aws-resources.sh"
  exit 1
fi
