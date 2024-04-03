#!/bin/sh

set -e

echo "Installing Prerequites..."

# Install JQ
if ! command -v jq >/dev/null 2>&1; then
    echo "JQ not found, installing"
    sudo apt install jq
else
    echo "JQ already installed"
fi

# Install Curl
if ! command -v curl >/dev/null 2>&1; then
    echo "Curl not found, installing"
    sudo apt install curl
else
    echo "Curl already installed"
fi

# Install K3S
if ! command -v k3s >/dev/null 2>&1; then
    echo "K3S not found, installing"
    curl -sfL https://get.k3s.io | sh -

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
else
    echo "K3S already installed"
fi

# Install Azure CLI
if ! command -v az >/dev/null 2>&1; then
    echo "Azure CLI not found, installing"
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
else
    echo "Azure CLI already installed"
fi

# Install mosquitto client
if ! command -v mosquitto_pub >/dev/null 2>&1; then
    echo "Mosquitto not found, installing"
    sudo apt-get update
    sudo apt-get install mosquitto-clients -y
else
    echo "Mosquitto Client already installed"
fi

# Install mqttui
if ! command -v mqttui >/dev/null 2>&1; then
    echo "mqttui not found, installing"
    wget https://github.com/EdJoPaTo/mqttui/releases/download/v0.19.0/mqttui-v0.19.0-x86_64-unknown-linux-gnu.deb
    apt-get install ./mqttui-v0.19.0-x86_64-unknown-linux-gnu.deb
    rm -rf ./mqttui-v0.19.0-x86_64-unknown-linux-gnu.deb
else
    echo "mqttui already installed"
fi

# Install Azure extensions: "connectedk8s,k8s-extension,azure-iot-ops"
az extension add --name connectedk8s
az extension add --name k8s-extension
az extension add --name azure-iot-ops

echo "Ending Prerequisites Install"
