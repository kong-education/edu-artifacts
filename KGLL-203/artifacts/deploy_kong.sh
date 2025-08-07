#! /bin/bash
## Kubernetes Installation

### Create Cluster Certificates

openssl rand -writerand .rnd
openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
  -keyout ./cluster.key -out ./cluster.crt \
  -days 1095 -subj "/CN=kong_clustering"


### Create Namespaces

kubectl create namespace kong
kubectl create namespace kong-dp


### Create Control Plane Secrets

kubectl -n kong create secret tls kong-cluster-cert --cert=./cluster.crt --key=./cluster.key
kubectl -n kong create secret tls kong-manager-tls --key="/etc/kong/ssl/server.key" --cert="/etc/kong/ssl/server.crt"
kubectl -n kong create secret tls kong-admin-tls --key="/etc/kong/ssl/server.key" --cert="/etc/kong/ssl/server.crt"
kubectl -n kong create secret tls kong-proxy-tls --key="/etc/kong/ssl/server.key" --cert="/etc/kong/ssl/server.crt"
kubectl -n kong create secret generic kong-enterprise-superuser-password --from-literal=password=password


### Load Kong License File

kubectl create secret generic kong-enterprise-license -n kong --from-file=license=/etc/kong/license.json

### Create Kong Manager Session Configuration Secret

cat << EOF > admin_gui_session_conf
{
    "cookie_name":"admin_session",
    "cookie_samesite":"off",
    "secret":"kong",
    "cookie_secure":true,
    "storage":"kong"
}
EOF
kubectl create secret generic kong-session-config -n kong --from-file=admin_gui_session_conf

### Create Data Plane Secrets

kubectl create secret tls kong-cluster-cert --cert=./cluster.crt --key=./cluster.key -n kong-dp
kubectl create secret generic kong-enterprise-license -n kong-dp --from-file=license=/etc/kong/license.json
kubectl create secret tls kong-proxy-tls -n kong-dp --key="/etc/kong/ssl/server.key" --cert="/etc/kong/ssl/server.crt"


### Add Helm Repository

helm repo add kong https://charts.konghq.com
helm repo update

### Configure Environment Variables

#export KONG_ADMIN_GUI_URL=https://${FQDN}:30500 
#export KONG_ADMIN_GUI_API_URL=https://${FQDN}:30501
#export KONG_PROXY_URL=https://${FQDN}:30443

yq -i '.env.admin_gui_url = env(KONG_ADMIN_GUI_URL)' cp-values.yaml
yq -i '.env.admin_gui_api_url = env(KONG_ADMIN_GUI_API_URL)' cp-values.yaml
yq -i '.env.proxy_url = env(KONG_PROXY_URL)' cp-values.yaml

### Deploy Control Plane

helm install -f cp-values.yaml kong kong/kong -n kong

### Deploy Data Plane

helm install -f dp-values.yaml kong kong/kong -n kong-dp

clear

### Wait for Control Plane to be Ready
echo "Waiting for Kong Control Plane to be ready. This can take up to 1 minute..."
kubectl -n kong rollout status deployment kong-kong --timeout=300s

if [ $? -ne 0 ]; then
  echo "Control Plane failed to become ready in time."
  exit 1
fi

echo "Control Plane is active!"
 
echo "Deploying Sample Gateway Service..."