#!/bin/bash
set -e

REGION="ap-south-2"
PROJECT_NAME="demo"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

safe_delete() {
  echo "  → $1"
  eval "$2" 2>/dev/null || echo "     (not found or already deleted)"
}

echo -e "${YELLOW}Starting full AWS cleanup in $REGION...${NC}"

# Step 0: Delete EKS Node Groups first
echo -e "${YELLOW}0. Deleting EKS Node Groups...${NC}"
NODE_GROUPS=$(aws eks list-nodegroups --cluster-name ${PROJECT_NAME}-eks --region $REGION --query 'nodegroups[*]' --output text 2>/dev/null || echo "")
for ng in $NODE_GROUPS; do
  safe_delete "Deleting node group: $ng" \
    "aws eks delete-nodegroup --cluster-name ${PROJECT_NAME}-eks --nodegroup-name $ng --region $REGION"
  echo "  Waiting for node group deletion..."
  aws eks wait nodegroup-deleted --cluster-name ${PROJECT_NAME}-eks --nodegroup-name $ng --region $REGION 2>/dev/null || true
done

# Step 1: Delete EKS Cluster
echo -e "${YELLOW}1. Deleting EKS Cluster...${NC}"
safe_delete "Deleting EKS cluster" \
  "aws eks delete-cluster --name ${PROJECT_NAME}-eks --region $REGION"

# Step 2: Delete IAM Roles (detach policies first)
echo -e "${YELLOW}2. Deleting IAM Roles...${NC}"
safe_delete "Detaching policy from ${PROJECT_NAME}-eks-cluster-role" \
  "aws iam detach-role-policy --role-name ${PROJECT_NAME}-eks-cluster-role --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
safe_delete "Deleting ${PROJECT_NAME}-eks-cluster-role" \
  "aws iam delete-role --role-name ${PROJECT_NAME}-eks-cluster-role"

for policy in \
  arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy \
  arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly \
  arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy; do
  safe_delete "Detaching $policy from ${PROJECT_NAME}-eks-node-role" \
    "aws iam detach-role-policy --role-name ${PROJECT_NAME}-eks-node-role --policy-arn $policy"
done
safe_delete "Deleting ${PROJECT_NAME}-eks-node-role" \
  "aws iam delete-role --role-name ${PROJECT_NAME}-eks-node-role"

# Step 3: Delete ALB and Target Groups
echo -e "${YELLOW}3. Deleting ALB and Target Groups...${NC}"
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

# Step 4: Delete S3 Bucket
echo -e "${YELLOW}4. Deleting S3 Bucket...${NC}"
safe_delete "Deleting S3 bucket" \
  "aws s3 rb s3://my-lb-logs-${PROJECT_NAME}-12345 --force"

# Step 5: Delete Security Groups
echo -e "${YELLOW}5. Deleting Security Groups...${NC}"
SG_ID=$(aws ec2 describe-security-groups --region $REGION --filters "Name=group-name,Values=allow-my-ip" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || echo "")
if [ "$SG_ID" != "None" ] && [ -n "$SG_ID" ]; then
  safe_delete "Deleting security group $SG_ID" \
    "aws ec2 delete-security-group --group-id $SG_ID --region $REGION"
fi

# Step 6: Delete NAT Gateways (releases EIPs)
echo -e "${YELLOW}6. Deleting NAT Gateways...${NC}"
NAT_IDS=$(aws ec2 describe-nat-gateways --region $REGION --filter Name=state,Values=available --query "NatGateways[*].NatGatewayId" --output text 2>/dev/null || echo "")
for nat_id in $NAT_IDS; do
  echo "  - Deleting NAT Gateway: $nat_id"
  aws ec2 delete-nat-gateway --nat-gateway-id $nat_id --region $REGION 2>/dev/null || true
done

if [ -n "$NAT_IDS" ]; then
  echo "  Waiting for NAT Gateways to be deleted..."
  sleep 30
fi

# Step 7: Release Elastic IPs
echo -e "${YELLOW}7. Releasing Elastic IPs...${NC}"
ALLOC_IDS=$(aws ec2 describe-addresses --region $REGION --query "Addresses[*].AllocationId" --output text 2>/dev/null || echo "")
for alloc_id in $ALLOC_IDS; do
  echo "  - Releasing EIP: $alloc_id"
  aws ec2 release-address --allocation-id $alloc_id --region $REGION 2>/dev/null || true
done

# Step 8: Get all non-default VPCs and delete them
echo -e "${YELLOW}8. Deleting VPCs and dependencies...${NC}"
VPC_IDS=$(aws ec2 describe-vpcs --region $REGION --filters "Name=isDefault,Values=false" --query "Vpcs[*].VpcId" --output text)

for VPC_ID in $VPC_IDS; do
  echo "  Processing VPC: $VPC_ID"
  
  NAT_GW_IDS=$(aws ec2 describe-nat-gateways --region $REGION --filter Name=vpc-id,Values=$VPC_ID --query "NatGateways[?State!='deleted'].NatGatewayId" --output text 2>/dev/null || echo "")
  for nat_gw_id in $NAT_GW_IDS; do
    echo "    - Deleting NAT Gateway: $nat_gw_id"
    aws ec2 delete-nat-gateway --nat-gateway-id $nat_gw_id --region $REGION 2>/dev/null || true
  done
  
  IGW_IDS=$(aws ec2 describe-internet-gateways --region $REGION --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[*].InternetGatewayId" --output text)
  for IGW_ID in $IGW_IDS; do
    echo "    - Detaching/Deleting IGW: $IGW_ID"
    aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION 2>/dev/null || true
    aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $REGION 2>/dev/null || true
  done
  
  SUBNET_IDS=$(aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output text)
  for SUBNET_ID in $SUBNET_IDS; do
    echo "    - Deleting Subnet: $SUBNET_ID"
    aws ec2 delete-subnet --subnet-id $SUBNET_ID --region $REGION 2>/dev/null || true
  done
  
  RT_IDS=$(aws ec2 describe-route-tables --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query "RouteTables[?Associations[0].Main != true].RouteTableId" --output text)
  for RT_ID in $RT_IDS; do
    echo "    - Deleting Route Table: $RT_ID"
    aws ec2 delete-route-table --route-table-id $RT_ID --region $REGION 2>/dev/null || true
  done
  
  SG_IDS=$(aws ec2 describe-security-groups --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[?GroupName!='default'].GroupId" --output text)
  for SG_ID in $SG_IDS; do
    echo "    - Deleting Security Group: $SG_ID"
    aws ec2 delete-security-group --group-id $SG_ID --region $REGION 2>/dev/null || true
  done
  
  # Delete Network Interfaces
  ENI_IDS=$(aws ec2 describe-network-interfaces --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query "NetworkInterfaces[*].NetworkInterfaceId" --output text 2>/dev/null || echo "")
  for ENI_ID in $ENI_IDS; do
    echo "    - Deleting Network Interface: $ENI_ID"
    aws ec2 delete-network-interface --network-interface-id $ENI_ID --region $REGION 2>/dev/null || true
  done
  
  echo "    - Deleting VPC: $VPC_ID"
  aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION 2>/dev/null || echo "      ⚠️ Could not delete VPC (may have remaining dependencies)"
done

echo ""
echo -e "${GREEN}✅ Full cleanup complete!${NC}"
echo ""
echo "Remaining VPCs:"
aws ec2 describe-vpcs --region $REGION --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0],IsDefault]' --output table
echo ""
echo "Remaining Elastic IPs:"
aws ec2 describe-addresses --region $REGION --query 'Addresses[*].[AllocationId,PublicIp]' --output table
