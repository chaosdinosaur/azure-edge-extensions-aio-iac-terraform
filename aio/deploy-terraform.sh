#!/bin/bash

set -e

install_prerequisites() {
    pushd ./provisioning
    ./00-install-prerequistes.sh
    popd
}

navigate_to_script_dir() {
    local script_dir=$(dirname "$0")
    cd $script_dir
    echo "Changed directory to $script_dir"
}

create_service_principal() {
    pushd ./provisioning
    local suffix="$1"
    local appName="sp-aio-$suffix"
    ./02-create-sp.sh $appName
    
    # Check if the servicePrincipal.json file exists
    if [ ! -f ~/.azure/servicePrincipal.json ]; then
        echo "File ~/.azure/servicePrincipal.json does not exist."
        exit 1
    fi
    popd
}

connect_to_arc() {
    pushd ./provisioning
    local suffix="$1"
    export RESOURCE_GROUP="aio$suffix"
    export CLUSTER_NAME="aio$suffix"
    export LOCATION="westus2"
    ./01-arc-connect.sh
    popd

    create_terraform_file
}

deploy_aio_resources() {
    pushd ./provisioning
    local suffix="$1"
    spAuthInfo=$(cat ~/.azure/servicePrincipal.json)
    clientId=$(echo $spAuthInfo | jq -r '.clientId')
    clientSecret=$(echo $spAuthInfo | jq -r '.clientSecret')
    
    if [ -z "$clientId" ] || [ -z "$clientSecret" ]; then
        echo "clientId or clientSecret does not exist in ~/.azure/servicePrincipal.json"
        exit 1
    fi
    
    export AKV_SP_CLIENT_ID=$clientId
    export AKV_SP_CLIENT_SECRET=$clientSecret
    export AKV_SP_OBJECT_ID=$(az ad sp show --id $AKV_SP_CLIENT_ID --query id -o tsv)
    
    ./03-aio-deploy-core.sh
    popd
}

create_terraform_file() {
    echo "Creating SSH Key..."
    local suffix="$1"
    local VM_USERNAME="admin$suffix"
    ssh-keygen -t rsa -b 4096 -C "$VM_USERNAME" -f ~/.ssh/id_aio_rsa

    export KEYVAULT_NAME=$(az keyvault list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv)
    export TERRAFORM_FILE="$CLUSTER_NAME.auto.tfvars"

    echo "Creating Terraform file..."
    cp ./sample-aio.auto.tfvars.example ./$TERRAFORM_FILE

    echo "resource_group_name          = \"$RESOURCE_GROUP\"" >> ./$TERRAFORM_FILE
    echo "arc_cluster_name             = \"$CLUSTER_NAME\"" >> ./$TERRAFORM_FILE
    echo "key_vault_name               = \"$KEYVAULT_NAME\"" >> ./$TERRAFORM_FILE

    sed -i 's/name\s*=\s*".*"/name             = "'$CLUSTER_NAME'"/' ./$TERRAFORM_FILE
    sed -i 's/location\s*=\s*".*"/location             = "'$AZURE_REGION'"/' ./$TERRAFORM_FILE
    sed -i 's/vm_computer_name\s*=\s*".*"/vm_computer_name             = "vm-'$CLUSTER_NAME'"/' ./$TERRAFORM_FILE
    sed -i 's/vm_username\s*=\s*".*"/vm_username                  = "'$VM_USERNAME'"/' ./$TERRAFORM_FILE
    sed -i 's|vm_ssh_pub_key_file\s*=\s*".*"|vm_ssh_pub_key_file          = "~/.ssh/id_aio_rsa.pub"|' ./$TERRAFORM_FILE
}

suffix=$(date +%s | cut -c6-10)
START_TIME=$(date +%s)
install_prerequisites
navigate_to_script_dir
create_service_principal $suffix
connect_to_arc $suffix
create_terraform_file $suffix
deploy_aio_resources $suffix
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "Deployment completed successfully in $DURATION seconds."
