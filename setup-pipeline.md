# Steps to Start Pipeline

## 1. Local EKS Access & LB Controller
```bash
aws eks update-kubeconfig --name demo-eks --region ap-south-2
# Install AWS Load Balancer Controller (for Ingress → ALB)
helm repo add eks https://aws.github.io/eks-charts
helm repo update
eksctl create iamserviceaccount \
  --cluster=demo-eks --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --approve --region ap-south-2
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system --set clusterName=demo-eks \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

## 2. GitHub Repo & Secrets
- Push this repo to GitHub.
- Repo Settings > Secrets/Variables:
  - `AWS_ACCOUNT_ID`: your AWS acct
  - `AWS_REGION`: ap-south-2
  - Add `OIDC_SUBJECT`: `repo:yourusername/eks-project:ref:refs/heads/main`

## 3. AWS IAM OIDC Roles (run once)
```bash
eksctl create iamidentitymapping \
  --cluster demo-eks --namespace kube-system \
  --service-account aws-load-balancer-controller \
  --arn arn:aws:iam::ACCOUNT:role/AmazonEKSLoadBalancerControllerRole \
  --region ap-south-2

# Create GitHubActionsRole
cat > github-role-trust.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:USERNAME/eks-project:ref:refs/heads/main"
        }
      }
    }
  ]
}
EOF
aws iam create-role --role-name GitHubActionsRole --assume-role-policy-document file://github-role-trust.json
aws iam attach-role-policy --role-name GitHubActionsRole --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
# Similar for EKSAdminRole with AmazonEKSClusterPolicy etc.
```

## 4. Test Pipeline
- Update workflow IAM ARNs with your ACCOUNT.
- `git push origin main`
- GH Actions → runs terraform/app → ALB DNS in `kubectl get ingress -n default`

## Outputs (terraform output)
SG_ID, S3_BUCKET_NAME for Ingress annotations (set as GH vars).
