# Deleting resources created by kubectl
kubectl delete -f prom-graphana.yml
kubectl delete -f split-ingress.yml
kubectl delete namespace monitoring


# to confirm deletion
kubectl get all -n monitoring
kubectl get ingress -A



# Delete resources formed by install_alb_controller.sh
helm uninstall aws-load-balancer-controller -n kube-system
eksctl delete iamserviceaccount \
  --cluster springboot-cluster \
  --name aws-load-balancer-controller \
  --namespace kube-system \
  --region us-east-2

# To list all OICDs
aws iam list-open-id-connect-providers

aws iam delete-policy --policy-arn arn:aws:iam::<your-account-id>:policy/AWSLoadBalancerControllerIAMPolicy
aws iam delete-open-id-connect-provider --open-id-connect-provider-arn arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E


# Lastly delete cluster created via Terraform
terraform destroy -auto-approve
