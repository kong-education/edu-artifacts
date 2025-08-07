#!/usr/bin/env bash

# Get control plane Pod from kubectl
KIC_POD=$(kubectl get pods --selector=app=kong-controller -n kong -o jsonpath='{.items[*].metadata.name}')

# Show logs
kubectl logs $KIC_POD -n kong
