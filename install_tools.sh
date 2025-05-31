#!/bin/bash

set -e

echo "🔧 Updating packages..."
sudo yum update -y

echo "📦 Installing curl, tar, gzip, unzip, jq..."
sudo yum install -y curl tar gzip unzip jq --allowerasing

echo "✅ Installing AWS CLI v2..."
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip
aws --version

echo "✅ Installing latest kubectl..."
K8S_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client

echo "✅ Installing eksctl (weaveworks/tap/eksctl)..."
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" -o eksctl.tar.gz
tar -xzf eksctl.tar.gz
sudo mv eksctl /usr/local/bin/
rm -f eksctl.tar.gz
eksctl version

echo "✅ Installing weaveworks tap CLI..."
TAP_LATEST=$(curl -s https://api.github.com/repos/weaveworks/tap/releases/latest | jq -r '.tag_name')
curl -LO "https://github.com/weaveworks/tap/releases/download/${TAP_LATEST}/tap-linux-amd64"
chmod +x tap-linux-amd64
sudo mv tap-linux-amd64 /usr/local/bin/tap
tap version || echo "ℹ️ 'tap' installed but may need login/config to show version."

echo "✅ All tools installed successfully!"
