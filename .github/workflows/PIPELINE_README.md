# Pipeline2 Workflow - 8 Steps to Production

## Triggers
- **Branch**: pipeline2 (automatic on push)
- **Manual**: via workflow_dispatch

---

## 8-STEP PIPELINE OVERVIEW

### Step 1: Build ✅
**What happens**: Installs dependencies and builds app
- Frontend: `npm run build` → creates dist/
- Backend: `npm run build 2>/dev/null` (if available)
- **Time**: ~2 mins
- **Fails if**: Missing package.json or build errors

### Step 2: Lint ✅
**What happens**: Checks code quality
- Backend ESLint
- Frontend ESLint
- **Time**: ~1 min
- **Fails if**: Linting errors (non-critical)

### Step 3: SonarQube ✅
**What happens**: Deep code analysis
- Scans for bugs
- Checks security vulnerabilities
- Detects code smells
- Enforces quality gate
- **Time**: ~2 mins
- **Fails if**: Quality gate threshold not met

### Step 4: Docker Build ✅
**What happens**: Creates Docker image
- Uses Dockerfile at root
- References new_app/app/ for source
- Builds multi-stage (frontend first, then runtime)
- Size: ~300MB
- **Time**: ~3 mins
- **Fails if**: Build errors or missing files

### Step 5: Trivy Security Scan ✅
**What happens**: Scans image for vulnerabilities
- Checks for HIGH/CRITICAL issues
- Uploads to GitHub Security
- **Time**: ~1 min
- **Fails if**: CRITICAL vulnerabilities found

### Step 6: Push ECR ✅
**What happens**: Uploads image to AWS ECR
- Logs into ECR (via OIDC role)
- Tags with commit SHA and `latest`
- Pushes image
- **Time**: ~1 min
- **Fails if**: AWS credentials invalid or ECR doesn't exist

### Step 7: EKS Access ✅
**What happens**: Configures kubectl access
- Updates kubeconfig
- Connects to EKS cluster
- **Time**: ~30 seconds
- **Fails if**: EKS cluster doesn't exist or invalid credentials

### Step 8: Helm Deploy ✅
**What happens**: Deploys app to Kubernetes
- Creates/updates Deployment
- Creates PVC (persistent storage)
- Creates Services (backend internal, frontend external)
- Creates Ingress (ALB routing)
- Waits for rollout
- **Time**: ~2-5 mins
- **Fails if**: Helm chart errors or Kubernetes issues

---

## SECRETS REQUIRED (GitHub Settings)

| Secret | Description | Example |
|--------|-------------|---------|
| AWS_OIDC_ROLE_ARN | IAM role for OIDC | arn:aws:iam::123456:role/GitHubActionsRole |
| EKS_CLUSTER_NAME | Kubernetes cluster | app-new-cluster |
| APP_HOSTNAME | Domain for app | app-new.yourdomain.com |
| SONAR_TOKEN | SonarCloud token | squ_xxxxxxxxxxxx... |
| SONAR_PROJECT_KEY | Project key | jonnamohit/Terraform |

## VARIABLES REQUIRED (GitHub Settings)

| Variable | Description | Example |
|----------|-------------|---------|
| AWS_REGION | AWS region | us-west-2 |
| ECR_REPO_URI | Full ECR repository | 123456789012.dkr.ecr.us-west-2.amazonaws.com/app-new |

---

## TROUBLESHOOTING

### Build Fails - "package.json not found"
- Check: `new_app/app/backend/package.json` exists
- Check: `new_app/app/frontend/package.json` exists

### SonarQube Fails - "Quality Gate failed"
- Check: SONAR_TOKEN is valid
- Check: SONAR_PROJECT_KEY matches SonarCloud
- Fix: Update code to pass quality rules

### Docker Build Fails
- Check: Dockerfile at root is valid
- Check: Paths in Dockerfile point to new_app/app/
- Test locally: `docker build -t app-new .`

### ECR Push Fails - "Not authorized"
- Check: AWS_OIDC_ROLE_ARN is correct
- Check: IAM role has ECRPushAccess policy
- Check: ECR_REPO_URI is correct format

### Helm Deploy Fails - "EKS not accessible"
- Check: EKS_CLUSTER_NAME exists
- Check: IAM role has EKS access
- Check: OIDC provider configured
- Test: `aws eks list-clusters`

---

## SUCCESS INDICATORS

✅ All steps complete (green checks)
✅ Image pushed to ECR: `aws ecr describe-images --repository-name app-new`
✅ Pods running: `kubectl get pods -n app-new`
✅ Ingress created: `kubectl get ingress -n app-new`
✅ App accessible: `curl <ALB-DNS>/api/users`

---

## MANUAL STEPS BEFORE PUSH

1. **Set GitHub Secrets**:
   - Settings → Secrets and variables → Actions
   - Add all 5 secrets

2. **Set GitHub Variables**:
   - Settings → Variables
   - Add AWS_REGION and ECR_REPO_URI

3. **AWS Prerequisites**:
   - ECR repository exists
   - EKS cluster exists with OIDC
   - Load Balancer Controller installed
   - EBS CSI Driver installed

4. **Code Ready**:
   - All tests passing locally
   - No build errors
   - SonarQube quality gate met

---

Next: Test Docker locally before pushing to pipeline2 branch!
