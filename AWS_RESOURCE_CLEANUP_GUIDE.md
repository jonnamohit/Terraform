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

Terraform's destroy step in the pipeline is using `continue-on-error: true`, which means:
- If destroy fails, pipeline continues anyway
- Old resources stay in AWS but state is deleted
- Next apply tries to create new resources with same names → conflicts

## Solutions

### ✅ Solution 1: Clean Up AWS Manually (Quick Fix)

```bash
# Make script executable
chmod +x cleanup-aws-resources.sh

# Run the cleanup script
./cleanup-aws-resources.sh

# Or provide credentials if not configured
AWS_REGION=ap-south-2 ./cleanup-aws-resources.sh
```

What it deletes:
- ✅ EKS cluster
- ✅ IAM roles (eks-cluster-role, eks-node-role)
- ✅ S3 bucket (my-lb-logs-demo-12345)
- ✅ Elastic IPs
- ✅ VPC and all subnets
- ✅ Internet Gateways
- ✅ Route tables

After cleanup, push new code and pipeline will succeed:
```bash
git push origin main
```

---

### ✅ Solution 2: Manual AWS CLI Cleanup

If you have AWS CLI configured:

```bash
REGION="ap-south-2"
PROJECT="demo"

# Delete EKS cluster
aws eks delete-cluster --name ${PROJECT}-eks --region $REGION

# Delete IAM roles
aws iam detach-role-policy \
  --role-name ${PROJECT}-eks-cluster-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
aws iam delete-role --role-name ${PROJECT}-eks-cluster-role

# Delete S3 bucket
aws s3 rb s3://my-lb-logs-demo-12345 --force

# Release Elastic IPs
aws ec2 release-address --allocation-id eipalloc-xxxxx --region $REGION

# Delete VPC
aws ec2 delete-vpc --vpc-id vpc-xxxxx --region $REGION
```

---

### ✅ Solution 3: AWS Console Manual Cleanup

1. **Go to AWS Console** → ap-south-2 region
2. **IAM** → Roles
   - Delete `demo-eks-cluster-role`
   - Delete `demo-eks-node-role`
3. **EKS** → Clusters
   - Delete `demo-eks` cluster (this will take 5-10 minutes)
4. **S3**
   - Delete bucket `my-lb-logs-demo-12345`
5. **EC2** → Elastic IPs
   - Release any unassociated addresses
6. **VPC** → VPCs
   - Delete `demo-vpc` (and associated subnets, IGWs, route tables)

---

### ✅ Solution 4: Request AWS Limit Increase

If you hit VPC/EIP limits:

1. **AWS Service Quotas Console**
2. Search for:
   - "VPC per region" → Request increase beyond 5
   - "Elastic IPs" → Request increase beyond 5
3. Submit request (instant approval usually)

---

### ✅ Solution 5: Use Different Project Names

Modify `env/dev/terraform.tfvars` to use unique names:

```hcl
# Before
project_name = "demo"
s3_bucket_name = "my-lb-logs-demo-12345"

# After (use timestamp or branch name)
project_name = "demo-${timestamp()}"
s3_bucket_name = "my-lb-logs-demo-${random(4)}"
```

---

### ✅ Solution 6: Fix Pipeline (Long-term)

Update `.github/workflows/pipeline.yml` to:
1. **NOT** use `continue-on-error: true` on destroy
2. **Import** existing resources into state before destroy
3. **Verify** destroy succeeded before apply

Already implemented in latest version. Just push:
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
aws ec2 describe-vpcs --region ap-south-2
# Should show 0 or fewer VPCs with "demo" tag
```

### Step 3: Push Clean Pipeline
```bash
git push origin main
```

### Step 4: Trigger Pipeline
```bash
# GitHub will auto-trigger on push, OR manually trigger:
gh workflow run .github/workflows/pipeline.yml
```

### Step 5: Monitor
Check pipeline at: https://github.com/jonnamohit/Terraform/actions

---

## Prevention Going Forward

✅ **Pipeline already updated to:**
- ✅ Remove `continue-on-error: true` from destroy (fail if destroy doesn't work)
- ✅ Import existing resources before destroy
- ✅ Verify resources are gone before applying

---

## Troubleshooting

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

### "Role is in use" error
The role might be attached to an EKS cluster. Delete the cluster first.

### "Subnet still in use"
EC2 instances might be using it. Check:
```bash
aws ec2 describe-network-interfaces --filters "Name=subnet-id,Values=subnet-xxxxx" --region ap-south-2
```

---

## Summary

Currently blocked by:
- ❌ 2 IAM roles already exist
- ❌ 1 S3 bucket already owned
- ❌ VPC limit exceeded (5 max in region)
- ❌ Elastic IP limit exceeded (5 max in region)

**Quick Fix:** Run `cleanup-aws-resources.sh` then push code ✅

**Long-term:** Pipeline will handle cleanup automatically (already fixed) ✅
