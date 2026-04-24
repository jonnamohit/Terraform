# Self-Hosted Runner Disk Space Solutions

## Problem
GitHub Actions self-hosted runner at `/home/ubuntu/actions-runner/` is running out of disk space when installing Terraform AWS provider (839MB).

## Root Causes
1. **Docker data accumulation** - Previous builds leave behind docker images/layers
2. **Terraform provider cache** - AWS provider (v6.42.0) is ~839MB
3. **Build artifacts** - Old workflow runs accumulate in `./_work` directory
4. **System cache** - Apt, logs, and temp files build up

## Quick Solutions

### 1️⃣ Run Manual Cleanup on Runner (Immediate)
```bash
ssh ubuntu@<runner-ip>
bash ~/Terraform/runner-cleanup.sh
df -h
```

This will free ~20-50GB depending on your runner state.

### 2️⃣ GitHub Actions Pipeline Cleanup (Automatic)
Our pipeline now includes aggressive cleanup:
- Stops Docker
- Removes all Docker data
- Clears apt cache
- Removes unused system tools (dotnet, swift, android tools)
- Clears logs and temp directories

This runs **automatically before each terraform init**.

### 3️⃣ Long-term Solutions

#### Option A: Increase Disk Size (Recommended)
Add more disk space to your runner machine:
```bash
# Check current disk
df -h

# Expand disk (varies by platform - AWS/Azure/GCP/On-prem)
# Example for AWS: expand EBS volume and resize filesystem
sudo growpart /dev/xvda 1  # or your device
sudo resize2fs /dev/xvda1   # or your filesystem
```

#### Option B: Use Smaller Terraform Provider
Downgrade AWS provider version (smaller binary):
```hcl
# In env/dev/versions.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.0"  # Smaller (~600MB) instead of 6.42 (~839MB)
    }
  }
}
```

#### Option C: Use Terraform Cloud/Enterprise
Offload Terraform execution to Terraform Cloud (no local provider installation):
```bash
# Setup Terraform Cloud
terraform login
# Then use cloud backend instead of local
```

#### Option D: Cleanup Workflow Step
Add this to clean workspace after each run:
```yaml
- name: Cleanup After Build
  if: always()
  run: |
    rm -rf .terraform
    rm -rf ~/terraform*
```

## Monitoring

### Check runner disk daily
```bash
ssh ubuntu@<runner-ip>
df -h
du -sh /var/lib/docker
du -sh /home/ubuntu/actions-runner
```

### Set up disk space alerting
```bash
#!/bin/bash
USAGE=$(df / | grep -oP '\d+(?=%)')
if [ "$USAGE" -gt 80 ]; then
  echo "⚠️ Disk usage: ${USAGE}% - Run cleanup!"
fi
```

## Recommended Actions

1. **Immediate**: Run `./runner-cleanup.sh` manually
2. **Short-term**: Monitor disk space daily
3. **Long-term**: Increase disk size or use Terraform Cloud

## Current Pipeline Changes
✅ Auto-cleanup on every run
✅ Aggressive docker & system cache removal
✅ Removes unnecessary system tools
✅ Clears logs and temp files

---

**Questions?** Check GitHub Actions logs for cleanup output:
```bash
grep "Aggressive disk cleanup" /var/log/actions-runner/
```
