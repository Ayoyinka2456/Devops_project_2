#!/bin/bash

echo "Initializing Terraform..."
cd terraform
terraform init
terraform apply -auto-approve

echo "Updating kubeconfig for springboot-cluster..."
aws eks --region us-east-2 update-kubeconfig --name springboot-cluster

echo "Deploying Spring Boot app..."
kubectl apply -f ../deployment-ingress.yml

echo "Deploying Prometheus and Grafana..."
kubectl apply -f ../prom-graphana.yml

echo "Deployment complete!"
