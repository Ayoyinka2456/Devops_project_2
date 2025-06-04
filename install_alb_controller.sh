#!/bin/bash
set -e

# Variables - change if needed
CLUSTER_NAME="springboot-cluster"
AWS_REGION="us-east-2"
NAMESPACE="kube-system"
SERVICE_ACCOUNT_NAME="aws-load-balancer-controller"
POLICY_NAME="AWSLoadBalancerControllerIAMPolicy"

echo "Fetching AWS Account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account ID: $AWS_ACCOUNT_ID"

echo "Checking if IAM OIDC provider is associated..."
OIDC_PROVIDER=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")
if ! eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --region $AWS_REGION --approve; then
  echo "Failed to associate IAM OIDC provider or it already exists"
else
  echo "IAM OIDC provider associated successfully."
fi

echo "Downloading AWS Load Balancer Controller IAM policy..."
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

echo "Checking if IAM policy $POLICY_NAME already exists..."
POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text)
if [ -z "$POLICY_ARN" ]; then
  echo "Creating IAM policy $POLICY_NAME..."
  POLICY_ARN=$(aws iam create-policy --policy-name $POLICY_NAME --policy-document file://iam_policy.json --query 'Policy.Arn' --output text)
  echo "Created IAM policy ARN: $POLICY_ARN"
else
  echo "IAM policy already exists with ARN: $POLICY_ARN"
fi

echo "Creating IAM service account with attached policy..."
eksctl create iamserviceaccount \
  --cluster $CLUSTER_NAME \
  --region $AWS_REGION \
  --namespace $NAMESPACE \
  --name $SERVICE_ACCOUNT_NAME \
  --attach-policy-arn $POLICY_ARN \
  --approve \
  --override-existing-serviceaccounts

echo "Adding EKS Helm repo and updating..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update

echo "Installing AWS Load Balancer Controller Helm chart..."
helm upgrade --install $SERVICE_ACCOUNT_NAME eks/aws-load-balancer-controller \
  -n $NAMESPACE \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=$SERVICE_ACCOUNT_NAME \
  --set region=$AWS_REGION

echo "Cleaning up iam_policy.json..."
rm -f iam_policy.json

echo "AWS Load Balancer Controller installation complete."
