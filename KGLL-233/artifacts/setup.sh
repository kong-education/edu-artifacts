#!/bin/bash

# Create Namespace
kubectl create namespace kgo
kubectl create namespace hybrid

openssl rand -writerand .rnd
openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
  -keyout ./cluster.key -out ./cluster.crt \
  -days 1095 -subj "/CN=kong_clustering"

kubectl create secret tls kong-cluster-tls --key=./cluster.key --cert=./cluster.crt -n hybrid

# Load License
kubectl create secret generic kong-enterprise-license -n hybrid --from-file=license=/etc/kong/license.json
kubectl create secret generic kong-enterprise-superuser-password \
  -n hybrid \
  --from-literal=password=kong

helm repo add kong https://charts.konghq.com
helm repo update
helm upgrade --install edukong kong/kong -n hybrid --values ./values.yaml
kubectl apply -f https://docs.konghq.com/assets/kubernetes-ingress-controller/examples/echo-service.yaml -n hybrid
# exec bash