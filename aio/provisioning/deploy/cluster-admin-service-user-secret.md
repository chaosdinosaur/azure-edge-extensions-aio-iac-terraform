kubectl create clusterrolebinding current-user-binding \
  --clusterrole cluster-admin \
  --user="${cluster_admin_oid}" \
  --dry-run=client -o yaml | kubectl apply -f -
 
kubectl create serviceaccount cluster-admin-user-token \
  -n default \
  --dry-run=client -o yaml | kubectl apply -f -
 
kubectl create clusterrolebinding cluster-admin-service-user-binding \
  --clusterrole cluster-admin \
  --serviceaccount default:cluster-admin-user-token \
  --dry-run=client -o yaml | kubectl apply -f -
 
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: cluster-admin-service-user-secret
  annotations:
    kubernetes.io/service-account.name: cluster-admin-user-token
type: kubernetes.io/service-account-token
EOF
 
TOKEN=$(kubectl get secret cluster-admin-service-user-secret -o jsonpath='{$.data.token}' | base64 -d | tr -d '\n')
 
az keyvault secret set -n az-connectedk8s-proxy \
  --vault-name "${aio_kv_name}" \
  --value "az connectedk8s proxy -g ${resource_group_name} -n ${arc_resource_name} --token $TOKEN"