#!/bin/bash

SKIP_RG=0

# Parse command-line arguments
while (( "$#" )); do
  case "$1" in
    --skip-rg)
      SKIP_RG=1
      shift
      ;;
    *)
      echo "Error: Invalid argument"
      exit 1
      ;;
  esac
done

# Delete Azure resources only if --skip-rg is not provided
if [ $SKIP_RG -eq 0 ]; then
    if [ -z "$RESOURCE_GROUP" ]; then
        RESOURCE_GROUP=$(kubectl get configmap azure-clusterconfig -o jsonpath='{.data.AZURE_RESOURCE_GROUP}' -n azure-arc)
    fi

    az group delete --name $RESOURCE_GROUP --yes --no-wait
    echo "Azure resource group '$RESOURCE_GROUP' is being deleted"
fi
