#!/usr/bin/env bash

# Get DP Pod from kubectl
GW_POD=$(kubectl get pods --selector=app=kong-gateway -n kong -o jsonpath='{.items[*].metadata.name}')

# Show logs
kubectl logs $GW_POD -n kong


