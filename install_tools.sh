#!/bin/bash

set -e

echo "🔧 Updating packages..."
sudo yum update -y

echo "📦 Installing curl, tar, gzip, unzip, jq..."
sudo yum install -y curl tar gzip unzip jq --allowerasing

echo "✅ Checking AWS CLI..."
if ! command -v aws &> /dev/null; then
    echo "➡️ Installing AWS CLI v2..."
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
else
    echo "✔️ AWS CLI already installed: $(aws --version)"
fi

echo "✅ Checking kubectl..."
if ! command -v kubectl &> /dev/null; then
    echo "➡️ Installing latest kubectl..."
    K8S_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
else
    echo "✔️ kubectl already installed: $(kubectl version --client --short)"
fi

echo "✅ Checking eksctl..."
if ! command -v eksctl &> /dev/null; then
    echo "➡️ Installing eksctl..."
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" -o eksctl.tar.gz
    tar -xzf eksctl.tar.gz
    sudo mv eksctl /usr/local/bin/
    rm -f eksctl.tar.gz
else
    echo "✔️ eksctl already installed: $(eksctl version)"
fi

echo "✅ Checking weaveworks tap CLI..."
if ! command -v tap &> /dev/null; then
    echo "➡️ Installing weaveworks tap CLI..."
    TAP_LATEST=$(curl -s https://api.github.com/repos/weaveworks/tap/releases/latest | jq -r '.tag_name')
    curl -LO "https://github.com/weaveworks/tap/releases/download/${TAP_LATEST}/tap-linux-amd64"
    chmod +x tap-linux-amd64
    sudo mv tap-linux-amd64 /usr/local/bin/tap
    tap version || echo "ℹ️ 'tap' installed but may need login/config to show version."
else
    echo "✔️ tap already installed: $(tap version || echo 'login/config may be required')"
fi

echo "✅ All tools installed successfully!"
