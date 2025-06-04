#!/bin/bash


terraform apply -target=module.vpc \
                -target=aws_iam_role.eks_cluster_role \
                -target=aws_iam_role.eks_node_group_role \
                -target=aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy \
                -target=aws_iam_role_policy_attachment.eks_cluster_AmazonEKSServicePolicy \
                -target=aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy \
                -target=aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly \
                -target=aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy \
                -auto-approve


terraform apply -target=aws_iam_role.alb_controller_role \
                -target=aws_iam_policy.alb_ingress_policy \
                -target=aws_iam_role_policy_attachment.alb_controller_attach \
                -auto-approve


terraform apply -target=aws_eks_cluster.eks_cluster \
                -target=aws_eks_node_group.eks_node_group \
                -auto-approve


aws eks update-kubeconfig --region us-east-2 --name springboot-eks-cluster

kubectl get nodes

// # Step 1: Download the policy JSON
curl -o iam-policy-alb.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

// # Step 2: Create the IAM policy
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam-policy-alb.json


eksctl utils associate-iam-oidc-provider \
  --region us-east-2 \
  --cluster springboot-eks-cluster \
  --approve

eksctl create iamserviceaccount \
  --cluster springboot-eks-cluster \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy \
  --approve


helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=springboot-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-east-2 \
  --set vpcId=$(aws eks describe-cluster --name springboot-eks-cluster --query "cluster.resourcesVpcConfig.vpcId" --output text)


# To deploy the ingress
kubectl apply -f deployment-ingress.yml
// # verify deployment
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack -f prom-grafana.yaml
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack -f prom-grafana.yml


// # Just to reconfirm
terraform apply -target=kubernetes_deployment.springboot_app \
                -target=kubernetes_service.springboot_service \
                -target=kubernetes_ingress_v1.springboot_ingress \
                -auto-approve


// # Port forwarding for Grafana -> LocalHost on port 3000
kubectl --namespace default port-forward $(kubectl get pod -n default -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=monitoring" -o name) 3000
// Access Grafana in browser:
// Open http://localhost:3000 ...-U & -P admin


// # Port forwarding for prometheus -> LocalHost on port 9090

kubectl --namespace default port-forward svc/monitoring-kube-prometheus-stack-prometheus 9090

// # Validate deployment
kubectl get pods -n default -l "release=monitoring"
