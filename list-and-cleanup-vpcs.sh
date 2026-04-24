#!/bin/bash

# Quick VPC and EIP List & Delete Script
# This will show you what VPCs and EIPs exist, then delete old ones

REGION="ap-south-2"

echo "================================================"
echo "Checking AWS Resources in $REGION"
echo "================================================"
echo ""
echo "Note: You need AWS credentials configured first!"
echo ""
echo "To configure AWS CLI, run:"
echo "  aws configure"
echo ""
echo "Then enter:"
echo "  - AWS Access Key ID"
echo "  - AWS Secret Access Key"
echo "  - Default region: $REGION"
echo "  - Default output format: json"
echo ""
echo "After configuring, run:"
echo "  bash list-and-cleanup-vpcs.sh cleanup"
echo ""
echo "================================================"
echo ""

if [ "$1" = "list" ] || [ -z "$1" ]; then
  echo "📋 Listing VPCs in $REGION:"
  aws ec2 describe-vpcs --region $REGION --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0],CidrBlock,IsDefault]' --output table
  
  echo ""
  echo "📋 Listing Elastic IPs in $REGION:"
  aws ec2 describe-addresses --region $REGION --query 'Addresses[*].[AllocationId,PublicIp,Tags[?Key==`Name`].Value|[0],AssociationId]' --output table
  
  echo ""
  echo "Run with 'cleanup' to delete resources:"
  echo "  bash list-and-cleanup-vpcs.sh cleanup"

elif [ "$1" = "cleanup" ]; then
  echo "🗑️  CLEANING UP RESOURCES..."
  echo ""
  
  # Get all non-default VPCs
  VPC_IDS=$(aws ec2 describe-vpcs \
    --region $REGION \
    --filters "Name=isDefault,Values=false" \
    --query "Vpcs[*].VpcId" \
    --output text)
  
  if [ -z "$VPC_IDS" ]; then
    echo "✅ No non-default VPCs found"
  else
    for VPC_ID in $VPC_IDS; do
      echo "Deleting VPC: $VPC_ID"
      
      # Delete Internet Gateways
      IGW_IDS=$(aws ec2 describe-internet-gateways \
        --region $REGION \
        --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
        --query "InternetGateways[*].InternetGatewayId" \
        --output text)
      
      for IGW_ID in $IGW_IDS; do
        echo "  - Detaching IGW: $IGW_ID"
        aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION 2>/dev/null || true
        echo "  - Deleting IGW: $IGW_ID"
        aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $REGION 2>/dev/null || true
      done
      
      # Delete Subnets
      SUBNET_IDS=$(aws ec2 describe-subnets \
        --region $REGION \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "Subnets[*].SubnetId" \
        --output text)
      
      for SUBNET_ID in $SUBNET_IDS; do
        echo "  - Deleting Subnet: $SUBNET_ID"
        aws ec2 delete-subnet --subnet-id $SUBNET_ID --region $REGION 2>/dev/null || true
      done
      
      # Delete Route Tables (except main)
      RT_IDS=$(aws ec2 describe-route-tables \
        --region $REGION \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "RouteTables[?Associations[0].Main != true].RouteTableId" \
        --output text)
      
      for RT_ID in $RT_IDS; do
        echo "  - Deleting Route Table: $RT_ID"
        aws ec2 delete-route-table --route-table-id $RT_ID --region $REGION 2>/dev/null || true
      done
      
      # Delete VPC
      echo "  - Deleting VPC: $VPC_ID"
      aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION 2>/dev/null || echo "    ⚠️ Could not delete VPC (may have dependencies)"
    done
  fi
  
  # Release Elastic IPs
  echo ""
  echo "Releasing Elastic IPs..."
  ALLOC_IDS=$(aws ec2 describe-addresses \
    --region $REGION \
    --query "Addresses[?AssociationId==null].AllocationId" \
    --output text)
  
  if [ -z "$ALLOC_IDS" ]; then
    echo "✅ No unassociated Elastic IPs found"
  else
    for ALLOC_ID in $ALLOC_IDS; do
      echo "  - Releasing: $ALLOC_ID"
      aws ec2 release-address --allocation-id $ALLOC_ID --region $REGION 2>/dev/null || echo "    ⚠️ Could not release"
    done
  fi
  
  echo ""
  echo "✅ Cleanup complete!"
  echo ""
  echo "Verify:"
  echo "  bash list-and-cleanup-vpcs.sh list"
fi
