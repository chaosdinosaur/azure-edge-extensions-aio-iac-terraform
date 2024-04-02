#!/bin/bash

set -e

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
    ./04-aio-deploy-bicep.sh
    ./05-aio-deploy-manifests.sh
    popd
}

suffix=$(date +%s | cut -c6-10)
START_TIME=$(date +%s)
navigate_to_script_dir
create_service_principal $suffix
connect_to_arc $suffix
deploy_aio_resources $suffix
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "Deployment completed successfully in $DURATION seconds."
