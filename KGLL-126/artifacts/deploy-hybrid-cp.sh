#!/bin/bash
 #artifacts

source /home/ubuntu/.envs

# Pull Docker Certs
cd /home/ubuntu/$KONG_COURSE_ID


export KUBECONFIG=/home/ubuntu/.kube/config

kubectl create namespace kongcp

openssl rand -writerand .rnd
openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
  -keyout ./cluster.key -out ./cluster.crt \
  -days 1095 -subj "/CN=kong_clustering"

# Create tLS certs
kubectl create secret tls kong-cluster-cert --cert=./cluster.crt --key=./cluster.key -n kongcp
kubectl -n kongcp create secret tls kong-manager-tls --key="/etc/kong/ssl/server.key" --cert="/etc/kong/ssl/server.crt"
kubectl -n kongcp create secret tls kong-admin-tls --key="/etc/kong/ssl/server.key" --cert="/etc/kong/ssl/server.crt"
#kubectl -n kongcp create secret tls kong-proxy-tls --key="/etc/kong/ssl/server.key" --cert="/etc/kong/ssl/server.crt"


# Load License
kubectl create secret generic kong-enterprise-license -n kongcp --from-file=license=/etc/kong/license.json

# Create Manager Config
cat << EOF > admin_gui_session_conf
{
    "cookie_name":"admin_session",
    "cookie_samesite":"off",
    "secret":"kong",
    "cookie_secure":true,
    "storage":"kong"
}
EOF
kubectl create secret generic kong-session-config -n kongcp --from-file=admin_gui_session_conf


# Add Helm Repo
helm repo add kong https://charts.konghq.com
helm repo update

# URLs for Kong Control Plane
yq -i '.env.admin_gui_url = env(KONG_ADMIN_GUI_URL)' dnb-cp-values.yaml
yq -i '.env.admin_gui_api_url = env(KONG_ADMIN_GUI_API_URL)' dnb-cp-values.yaml


kubectl create secret generic kong-enterprise-superuser-password --from-literal=password=password -n kongcp

# Deploy Kong Data Plane
#kubectl create namespace kong-dp
#kubectl -n kong-dp create secret tls kong-cluster-cert --cert=./cluster.crt --key=./cluster.key 
#kubectl -n kong-dp create secret generic kong-enterprise-license --from-file=license=/etc/kong/license.json
#yq -i '.gateway.env.proxy_url = env(KONG_PROXY_URL)' dnb-dp-values.yaml

helm install -f dnb-cp-values.yaml kongcp kong/kong -n kongcp


#GW_WAIT_POD=$(kubectl get pods --selector=app=kong-gateway -n kong -o jsonpath='{.items[*].metadata.name}')
#CONTROLLER_WAIT_POD=$(kubectl get pods --selector=app=kong-controller -n kong -o jsonpath='{.items[*].metadata.name}')
#echo "Kong Gateway and Controller pods created. Waiting for them to come online..."
#kubectl wait --for=condition=Ready --timeout=300s pod $GW_WAIT_POD -n kong
#kubectl wait --for=condition=Ready --timeout=300s pod $CONTROLLER_WAIT_POD -n kong


#echo ""
#echo "The system is ready"