#!/bin/bash

logger -i -p info -t STRIGO "Running create_k8s_dataplane script."
source ~/$KONG_COURSE_ID/setScriptConfig

DECK_KONNECT_TOKEN=$(cat $PATFILE)

# Create control plane if it doesnt exist and read endpoints to env vars
source /home/ubuntu/$KONG_COURSE_ID/setRTG.sh
export KONG_CLUSTER_SERVER_NAME=$(https GET $KAPI/runtime-groups --auth-type=bearer --auth=$DECK_KONNECT_TOKEN | jq -r '.data[] | select(.name ==  "'$CP_NAME'") | .config.control_plane_endpoint' | cut -c 9-)
export KONG_CLUSTER_TELEMETRY_SERVER_NAME=$(https GET $KAPI/runtime-groups --auth-type=bearer --auth=$DECK_KONNECT_TOKEN | jq -r '.data[] | select(.name == "'$CP_NAME'") | .config.telemetry_endpoint' | cut -c 9-)
export KONG_CLUSTER_CONTROL_PLANE=$KONG_CLUSTER_SERVER_NAME:443
export KONG_CLUSTER_TELEMETRY_ENDPOINT=$KONG_CLUSTER_TELEMETRY_SERVER_NAME:443


# printf "\n\n${grn}Control plane endpoints discovered.\n${nrm}"
# echo $KONG_CLUSTER_SERVER_NAME
# echo $KONG_CLUSTER_TELEMETRY_SERVER_NAME
# echo $KONG_CLUSTER_CONTROL_PLANE
# echo $KONG_CLUSTER_TELEMETRY_ENDPOINT


# printf "\n\n${grn}Removing conplane configuration.${nrm}\n\n"
yes | deck reset  > /dev/null 2>&1
# Create KIND cluster
# kind delete cluster

logger -i -p info -t STRIGO "Recreating Kubernetes Cluster."

printf "\n\n${grn}(Re)creating Kubernetes cluster.${nrm}\n\n"
kind delete cluster
kind create cluster --config kind.yaml
kubectl create namespace kong
helm repo add kong https://charts.konghq.com
helm repo update

# Get RTG ID
CPID=$(cat $RTGIDF)

logger -i -p info -t STRIGO "Configuring Cluster Certificate."

CK=$(cat /etc/kong/ssl/cluster.crt)
https POST $KAPI/runtime-groups/$RTGID/dp-client-certificates cert="$CK" > /dev/null 2>&1


logger -i -p info -t STRIGO "Starting Kong."
kubectl create secret tls kong-cluster-cert -n kong \
    --cert=/etc/kong/ssl/cluster.crt \
    --key=/etc/kong/ssl/cluster.key

cp  ~/$KONG_COURSE_ID/values.yaml.template  ~/$KONG_COURSE_ID/values.yaml
yq -i '.env.cluster_control_plane = env(KONG_CLUSTER_CONTROL_PLANE)' ~/$KONG_COURSE_ID/values.yaml
yq -i '.env.cluster_server_name = env(KONG_CLUSTER_SERVER_NAME)' ~/$KONG_COURSE_ID/values.yaml
yq -i '.env.cluster_telemetry_endpoint = env(KONG_CLUSTER_TELEMETRY_ENDPOINT)' ~/$KONG_COURSE_ID/values.yaml
yq -i '.env.cluster_telemetry_server_name = env(KONG_CLUSTER_TELEMETRY_SERVER_NAME)' ~/$KONG_COURSE_ID/values.yaml

helm install $DPNAME kong/kong -n kong --values ~/$KONG_COURSE_ID/values.yaml

# helm  -n kong delete kong-dp
logger -i -p info -t STRIGO "Waiting for Kong to Start up..."
while [[ $(kubectl get pods -n kong -l app=$DPNAME-kong -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
   sleep 1
done

logger -i -p info -t STRIGO "KONG STARTED UP SUCCESSFULLY."
kubectl get pod -n kong
# kubectl get pod -n kong -w
kubectl -n kong patch service $DPNAME-kong-proxy --patch-file=patch-proxy.yaml

# Syncing BanKonG state file to control plane
