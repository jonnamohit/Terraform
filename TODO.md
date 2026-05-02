# Pipeline Fix Status

✅ FIXED:
- SonarCloud: Added projectBaseDir and proper args
- Docker build: Fixed ${{ env.ECR_REPOSITORY }} usage
- AWS_REGION: Changed to ap-south-2
- eks-connect: Fixed role-arn → role-to-assume

⏳ PENDING:
- helm-deploy: role-arn → role-to-assume
- smoke-test: role-arn → role-to-assume  
- GitHub Secrets: ECR_REPO_URI, EKS_CLUSTER_NAME, AWS_OIDC_ROLE_ARN

**Next Steps:**
1. Fix remaining 2 AWS credential blocks
2. Set GitHub secrets
3. Push to pipeline2 branch
4. Test pipeline
