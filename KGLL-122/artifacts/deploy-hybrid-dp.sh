#!/bin/bash
 #artifacts

source /home/ubuntu/.envs

# Pull Docker Certs
cd /home/ubuntu/$KONG_COURSE_ID


export KUBECONFIG=/home/ubuntu/.kube/config

kubectl create namespace kong-extranet-dp

# Create tLS certs
kubectl create secret tls kong-cluster-cert --cert=./cluster.crt --key=./cluster.key -n kong-extranet-dp
kubectl -n kong-extranet-dp create secret tls kong-proxy-tls --key="/etc/kong/ssl/server.key" --cert="/etc/kong/ssl/server.crt"


# Load License
kubectl create secret generic kong-enterprise-license -n kong-extranet-dp --from-file=license=/etc/kong/license.json


# Add Helm Repo
helm repo add kong https://charts.konghq.com
helm repo update

# Deploy Kong Data Plane
yq -i '.env.proxy_url = env(KONG_PROXY_URL)' dnb-dp-values.yaml

helm install -f dnb-dp-values.yaml kong-extranet-dp kong/kong -n kong-extranet-dp


#GW_WAIT_POD=$(kubectl get pods --selector=app=kong-gateway -n kong -o jsonpath='{.items[*].metadata.name}')
#CONTROLLER_WAIT_POD=$(kubectl get pods --selector=app=kong-controller -n kong -o jsonpath='{.items[*].metadata.name}')
#echo "Kong Gateway and Controller pods created. Waiting for them to come online..."
#kubectl wait --for=condition=Ready --timeout=300s pod $GW_WAIT_POD -n kong
#kubectl wait --for=condition=Ready --timeout=300s pod $CONTROLLER_WAIT_POD -n kong


#echo ""
#echo "The system is ready"