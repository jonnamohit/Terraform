# Terraform Workspace - app_new CI/CD Pipeline

## Overview
Full-stack user management app (React + Express/SQLite) with GitHub Actions CI/CD pipeline deploying to AWS EKS via Helm.

## Key Files
- **new_app/**: Source code, Dockerfile (nginx + node backend)
- **.github/workflows/ci-cd.yml**: Complete pipeline (test/Sonar/Trivy/ECR/Helm)
- **helm/app-new/**: Helm chart (Deployment, PVC, Services, Ingress)

## Quick Start
1. Configure GitHub Secrets & repo vars:
   ```
   AWS_REGION: us-west-2
   AWS_ACCOUNT_ID: 123456789012
   ECR_REPO_NAME: app-new
   ECR_REPO_URI: 123456789012.dkr.ecr.us-west-2.amazonaws.com/app-new
   EKS_CLUSTER_NAME: app-new-cluster
   SONAR_TOKEN: [SonarCloud token]
   SONAR_PROJECT_KEY: jonnamohit/Terraform
   APP_HOSTNAME: your-app.yourdomain.com
   AWS_OIDC_ROLE_ARN: arn:aws:iam::123456:role/GitHubActionsRole  # OIDC
   ```

2. Create ECR repo, EKS cluster, IAM OIDC provider/role.

3. Install prereqs in EKS:
   ```
   # AWS Load Balancer Controller
   helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system ...

   # EBS CSI driver
   ...

   # Cert-Manager if TLS needed
   ```

4. Push to `pipeline2` branch:
   ```
   git add .
   git commit -m "Complete CI/CD pipeline"
   git push origin pipeline2
   ```

5. Monitor: GitHub > Actions tab.

## Pipeline Steps (Matches task)
✅ Checkout source code  
✅ Validate/build app  
✅ SonarQube scan & Quality Gate  
✅ Docker build  
✅ Trivy scan  
✅ ECR tag/push  
✅ EKS access  
✅ Helm deploy: Deployment, PV/PVC (data persistence), backend internal service, frontend ALB service, Ingress routing (/ frontend, /api backend)

## Customization
- Update `values.yaml`: storage size, replicas, resources
- Ingress host in secrets
- Service annotations for ALB/NLB

## Local Test
```
cd new_app
docker build -t app-new .
docker run -p 8080:80 -v $(pwd)/app/backend/data:/app/backend/data app-new
```

## K8s Verify
```
kubectl get all -n app-new
kubectl get ingress -n app-new
kubectl describe pvc -n app-new
```
