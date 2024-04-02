#!/bin/sh

set -e

echo "Installing Prerequites..."

# Install K3S
if ! command -v k3s >/dev/null 2>&1; then
    echo "K3S not found, installing"
    curl -sfL https://get.k3s.io | sh -
    curl -sfL https://get.k3s.io | K3S_URL=https://myserver:6443 K3S_TOKEN=mynodetoken sh -
else
    echo "K3S already installed"
fi

mkdir ~/.kube
sudo KUBECONFIG=~/.kube/config:/etc/rancher/k3s/k3s.yaml kubectl config view --flatten > ~/.kube/merged
mv ~/.kube/merged ~/.kube/config
chmod  0600 ~/.kube/config
export KUBECONFIG=~/.kube/config
#switch to k3s context
kubectl config use-context default

echo fs.inotify.max_user_instances=8192 | sudo tee -a /etc/sysctl.conf
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf

sudo sysctl -p

echo fs.file-max = 100000 | sudo tee -a /etc/sysctl.conf

sudo sysctl -p

# Install Azure CLI
if ! command -v az >/dev/null 2>&1; then
    echo "Azure CLI not found, installing"
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
else
    echo "Azure CLI already installed"
fi

# Install Azure extensions: "connectedk8s,k8s-extension,azure-iot-ops"
az extension add --name connectedk8s
az extension add --name k8s-extension
az extension add --name azure-iot-ops

echo "Ending Prerequisites Install"
