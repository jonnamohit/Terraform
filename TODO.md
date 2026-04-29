# app_new CI/CD Pipeline TODO

Status: Completed ✅

Files created:
- .github/workflows/ci-cd.yml: Full GitHub Actions pipeline (validate, SonarCloud, Quality Gate, Docker build/Trivy, ECR push, Helm deploy)
- helm/app-new/Chart.yaml
- helm/app-new/values.yaml
- helm/app-new/templates/deployment.yaml, pvc.yaml, backend-service.yaml, frontend-service.yaml, ingress.yaml

## Setup Instructions:
1. Update helm/app-new/values.yaml with your ECR image, host.
2. Add GitHub Secrets:
   - AWS_REGION (e.g. us-west-2)
   - AWS_ACCOUNT_ID
   - ECR_REPO_NAME: app-new
   - EKS_CLUSTER_NAME: your-eks-cluster
   - SONAR_TOKEN (SonarCloud)
   - SONAR_PROJECT_KEY: your/project
   - APP_HOSTNAME: app-new.example.com
   - (Optional) AWS_ACCESS_KEY_ID/SECRET_ACCESS_KEY or setup OIDC role

3. git add . && git commit -m "Add CI/CD pipeline" && git push origin pipeline2

4. Go to GH repo > Actions > Enable workflows.

5. Verify deploy: kubectl get all -n app-new

## AWS Prereqs:
- ECR repo created
- EKS cluster with OIDC provider, IAM role for GH Actions
- AWS LB Controller, EBS CSI driver installed
- Helm repo if needed
