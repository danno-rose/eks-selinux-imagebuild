
kubectl get  node -o json | jq '.items[].status.addresses[0].type' -r