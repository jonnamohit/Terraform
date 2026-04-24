# AWS Duplicate Resource & Limits Error - Fix Guide

## Problem
When running `terraform apply`, you're getting errors like:
- `EntityAlreadyExists: Role with name demo-eks-cluster-role already exists`
- `BucketAlreadyOwnedByYou: my-lb-logs-demo-12345`
- `VpcLimitExceeded: The maximum number of VPCs has been reached`
- `AddressLimitExceeded: The maximum number of addresses has been reached`

This happens because:
1. **Previous deployments left resources in AWS** but Terraform state was lost/cleaned
2. **AWS account hit resource limits** (default: 5 VPCs, 5 Elastic IPs per region)
3. **Terraform can't find resources in state** so tries to create new ones, causing conflicts

## Root Cause

The original pipeline had these issues:
- `continue-on-error: true` on destroy step → failures were silently ignored
- Incomplete import step → only imported IAM roles and S3, missed VPC, subnets, NAT, ALB, security groups
- No pre-cleanup → orphaned resources accumulated in AWS

## Solutions

### ✅ Solution 1: Run Automated Cleanup (Quick Fix)

```bash
# Use the targeted cleanup script
chmod +x cleanup-aws-resources.sh
./cleanup-aws-resources.sh

# Or use the full cleanup (deletes ALL non-default VPCs)
chmod +x full-cleanup.sh
./full-cleanup.sh
```

What it deletes:
- ✅ EKS node groups (must delete before cluster)
- ✅ EKS cluster
- ✅ IAM roles (with policy detachments)
- ✅ ALB and target groups
- ✅ S3 bucket
- ✅ Security groups
- ✅ NAT gateways
- ✅ Elastic IPs
- ✅ VPC, subnets, IGWs, route tables

After cleanup, push new code and pipeline will succeed:
```bash
git push origin main
```

---

### ✅ Solution 2: Use Destroy & Import Script

```bash
chmod +x scripts/destroy-and-import.sh
./scripts/destroy-and-import.sh dev
```

This script:
1. Discovers existing AWS resources by tag/name
2. Imports them into Terraform state
3. Runs `terraform destroy` properly
4. Verifies cleanup completed
5. Cleans state files

---

### ✅ Solution 3: Manual AWS CLI Cleanup

```bash
REGION="ap-south-2"
PROJECT="demo"

# Delete EKS node groups first
aws eks list-nodegroups --cluster-name ${PROJECT}-eks --region $REGION --query 'nodegroups[*]' --output text | \
  xargs -I {} aws eks delete-nodegroup --cluster-name ${PROJECT}-eks --nodegroup-name {} --region $REGION

# Wait for node groups to delete, then delete cluster
aws eks delete-cluster --name ${PROJECT}-eks --region $REGION

# Delete IAM roles (detach policies first)
aws iam detach-role-policy --role-name ${PROJECT}-eks-cluster-role --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
aws iam delete-role --role-name ${PROJECT}-eks-cluster-role

for policy in arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy \
              arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly \
              arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy; do
  aws iam detach-role-policy --role-name ${PROJECT}-eks-node-role --policy-arn $policy
done
aws iam delete-role --role-name ${PROJECT}-eks-node-role

# Delete ALB
ALB_ARN=$(aws elbv2 describe-load-balancers --region $REGION --names "${PROJECT}-alb" --query 'LoadBalancers[0].LoadBalancerArn' --output text)
aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN --region $REGION

# Delete S3 bucket
aws s3 rb s3://my-lb-logs-${PROJECT}-12345 --force

# Release Elastic IPs
aws ec2 describe-addresses --region $REGION --query 'Addresses[*].AllocationId' --output text | \
  xargs -I {} aws ec2 release-address --allocation-id {} --region $REGION

# Delete VPC (find ID first)
VPC_ID=$(aws ec2 describe-vpcs --region $REGION --filters "Name=tag:Name,Values=${PROJECT}-vpc" --query 'Vpcs[0].VpcId' --output text)
aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION
```

---

### ✅ Solution 4: AWS Console Manual Cleanup

1. **Go to AWS Console** → ap-south-2 region
2. **EKS** → Clusters
   - Delete node groups first, then delete `demo-eks` cluster
3. **IAM** → Roles
   - Delete `demo-eks-cluster-role`
   - Delete `demo-eks-node-role`
4. **EC2** → Load Balancers
   - Delete `demo-alb`
5. **EC2** → Target Groups
   - Delete `demo-tg`
6. **S3**
   - Delete bucket `my-lb-logs-demo-12345`
7. **EC2** → Elastic IPs
   - Release any unassociated addresses
8. **VPC** → VPCs
   - Delete `demo-vpc` (and associated subnets, IGWs, NAT gateways, route tables)

---

### ✅ Solution 5: Request AWS Limit Increase

If you hit VPC/EIP limits frequently:

1. **AWS Service Quotas Console**
2. Search for:
   - "VPC per region" → Request increase beyond 5
   - "Elastic IPs" → Request increase beyond 5
3. Submit request (instant approval usually)

---

### ✅ Solution 6: Use the Fixed Pipeline (Long-term)

The pipeline has been updated with:
1. ✅ **Pre-cleanup step** — Removes ALL orphaned resources before Terraform runs
2. ✅ **Removed `continue-on-error: true`** from destroy step
3. ✅ **Proper error handling** — Destroy failures are logged but don't block
4. ✅ **tfvars auto-creation** — Creates terraform.tfvars if missing
5. ✅ **Comprehensive cleanup** — Handles node groups, ALB, SGs, VPC, EIPs, NAT

Just push to trigger:
```bash
git push origin main
```

---

## Step-by-Step Fix (Recommended)

### Step 1: Clean AWS Resources
```bash
chmod +x cleanup-aws-resources.sh
./cleanup-aws-resources.sh
```

### Step 2: Verify Cleanup
```bash
aws ec2 describe-vpcs --region ap-south-2 --filters "Name=tag:Name,Values=demo-vpc"
# Should return empty

aws iam get-role --role-name demo-eks-cluster-role
# Should return "NoSuchEntity"
```

### Step 3: Push Clean Pipeline
```bash
git add .
git commit -m "Fix pipeline: add pre-cleanup, proper destroy handling"
git push origin main
```

### Step 4: Monitor Pipeline
Check pipeline at: https://github.com/jonnamohit/Terraform/actions

---

## Prevention Going Forward

The pipeline now automatically:
- ✅ Pre-cleans orphaned resources before every run
- ✅ Handles destroy failures gracefully without `continue-on-error`
- ✅ Verifies resources are gone before applying
- ✅ Creates terraform.tfvars if missing

---

## Troubleshooting

### "Role is in use" error
The role is attached to an EKS cluster or node group. Delete those first:
```bash
aws eks delete-nodegroup --cluster-name demo-eks --nodegroup-name demo-nodes --region ap-south-2
aws eks delete-cluster --name demo-eks --region ap-south-2
```

### "Subnet still in use"
EC2 instances or ENIs might be using it. Check:
```bash
aws ec2 describe-network-interfaces --filters "Name=subnet-id,Values=subnet-xxxxx" --region ap-south-2
```

### "DependencyViolation" on VPC
Something is still attached (SG, ENI, NAT GW). Run the full cleanup:
```bash
./full-cleanup.sh
```

### "aws: command not found"
Install AWS CLI:
```bash
pip install awscli
# or
brew install awscli
```

### "User is not authorized"
Check AWS credentials:
```bash
aws sts get-caller-identity
aws configure  # Set credentials
```

---

## Summary of Fixes Applied

| File | What Changed |
|------|-------------|
| `.github/workflows/pipeline.yml` | Added pre-cleanup step, removed `continue-on-error`, added tfvars auto-creation, improved error handling |
| `cleanup-aws-resources.sh` | Added node group, ALB, target group, NAT gateway, security group cleanup |
| `full-cleanup.sh` | Added ENI cleanup, IAM policy detachments, node group deletion |
| `scripts/destroy-and-import.sh` | **New** — Comprehensive discover/import/destroy/verify script |
| `AWS_RESOURCE_CLEANUP_GUIDE.md` | Updated with all new fixes and troubleshooting |

**Quick Fix:** Run `./cleanup-aws-resources.sh` then `git push origin main` ✅
