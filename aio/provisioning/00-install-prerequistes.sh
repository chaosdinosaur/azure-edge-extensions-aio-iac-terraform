#!/bin/sh

set -e

echo "Installing Prerequites..."

# This env var is important to allow k3s to support shared mounts, required for CSI driver
# Temporary fix until made default https://github.com/k3d-io/k3d/pull/1268#issuecomment-1745466499
export K3D_FIX_MOUNTS=1

# Install K3D
if ! command -v k3d >/dev/null 2>&1; then
    echo "K3D not found, installing"
    curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | sh
else
    echo "K3D already installed"
fi
# Create local registry for K3D and local development
if [ "$(docker ps -f name=k3d-devregistry.localhost -q)" ]; then
    echo "Registry already exists so this is a rebuild of Dev Container, skipping"
else
    k3d registry create devregistry.localhost --port 5500
fi

# Create k3d cluster with NFS support and forwarded ports
# See https://github.com/jlian/k3d-nfs
if [ "$(k3d cluster list | grep devcluster)" ]; then
    echo "Cluster already exists so this is a rebuild of Dev Container, resetting context"
    k3d kubeconfig merge devcluster --kubeconfig-merge-default
else
    k3d cluster create devcluster --registry-use k3d-devregistry.localhost:5500 -i ghcr.io/jlian/k3d-nfs:v1.25.3-k3s1 \
    -p '1883:1883@loadbalancer' \
    -p '8883:8883@loadbalancer' \
    -p '6001:6001@loadbalancer' \
    -p '4000:80@loadbalancer'
fi

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