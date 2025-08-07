# KGLL-212-00.md
. ./start_lab.sh

# KGLL-212-01.md
yq -i '.networking.apiServerAddress = env(KIND_HOST)' ./base/kind-config.yaml
cat ./base/kind-config.yaml

kind create cluster --config ./base/kind-config.yaml
kubectl cluster-info

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.0/manifests/calico.yaml
kubectl -n kube-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true


# KGLL-212-02.md
openssl rand -writerand .rnd
openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
  -keyout ./cluster.key -out ./cluster.crt \
  -days 1095 -subj "/CN=kong_clustering"
kubectl create namespace kong
kubectl create secret tls kong-cluster-cert --cert=./cluster.crt --key=./cluster.key -n kong

# KGLL-212-03.md
kubectl create secret generic kong-enterprise-license -n kong --from-file=license=/etc/kong/license.json

cat << EOF > admin_gui_session_conf
{
    "cookie_name":"admin_session",
    "cookie_samesite":"off",
    "secret":"kong",
    "cookie_secure":false,
    "storage":"kong"
}
EOF
kubectl create secret generic kong-session-config -n kong --from-file=admin_gui_session_conf

kubectl create secret generic kong-enterprise-superuser-password --from-literal=password=password -n kong

cat << EOF > portal_gui_session_conf
{
    "cookie_name":"portal_session",
    "cookie_samesite":"off",
    "secret":"kong",
    "cookie_secure":true,
    "cookie_domain":".labs.konghq.com",
    "storage":"kong"
}
EOF
kubectl create secret generic kong-portal-session-config -n kong --from-file=portal_session_conf=portal_gui_session_conf

kubectl create namespace kong-dp
kubectl create secret tls kong-cluster-cert --cert=./cluster.crt --key=./cluster.key -n kong-dp
kubectl create secret generic kong-enterprise-license -n kong-dp --from-file=license=/etc/kong/license.json


# KGLL-212-04.md
helm repo add kong https://charts.konghq.com
helm repo update
yq -i '.env.admin_gui_url = env(KONG_MANAGER_URL)' ./base/cp-values.yaml
yq -i '.env.admin_api_url = env(KONG_ADMIN_API_URL)' ./base/cp-values.yaml
yq -i '.env.admin_api_uri = env(KONG_ADMIN_API_URI)' ./base/cp-values.yaml
yq -i '.env.proxy_url = env(KONG_PROXY_URL)' ./base/cp-values.yaml
yq -i '.env.portal_api_url = env(KONG_PORTAL_API_URL)' ./base/cp-values.yaml
yq -i '.env.portal_gui_host = env(KONG_PORTAL_GUI_HOST)' ./base/cp-values.yaml

yq '.env' ./base/cp-values.yaml
env|grep KONG_

# # Nginx Fix
# kubectl -n kong create configmap custom-nginx-template --from-file=/usr/local/kong/nginx-template.yaml
# kubectl -n kong create configmap custom-nginx-template --from-file=./base/nginx/nginx-template.yaml
# # Nginx Fix


helm install -f ./base/cp-values.yaml kong kong/kong -n kong \
    --set manager.ingress.hostname=${FQDN} \
    --set portal.ingress.hostname=${FQDN} \
    --set admin.ingress.hostname=${FQDN} \
    --set portalapi.ingress.hostname=${FQDN}

# helm uninstall kong -n kong

kubectl get pods -n kong

helm install -f ./base/dp-values.yaml kong-dp kong/kong -n kong-dp \
--set proxy.ingress.hostname=${FQDN}

kubectl get pods -n kong-dp

kubectl apply -f ./base/httpbin.yaml && kubectl apply -f ./base/httpbin-ingress.yaml 
http get $KONG_PROXY_URL/httpbin


# KGLL-212-05.md
## Developer Portal Ommitted


# KGLL-212-06.md
yq -i '.kong-addr = env(KONG_ADMIN_API_URL)' ./deck/deck.yaml 
cat ./deck/deck.yaml 
deck dump --config deck/deck.yaml --output-file deck/preupgrade.yaml
yq -i '.ingressController.image.tag = "2.5"' ./base/cp-values.yaml
yq -i '.image.tag = "2.8.1.1-alpine"' ./base/dp-values.yaml
yq -i '.image.tag = "2.8.1.1-alpine"' ./base/cp-values.yaml
yq '.ingressController.image.tag' ./base/cp-values.yaml
yq '.image.tag' ./base/cp-values.yaml
yq '.image.tag' ./base/dp-values.yaml
helm upgrade -f ./base/dp-values.yaml kong-dp kong/kong -n kong-dp \
--set proxy.ingress.hostname=$KONG_PROXY_URI --wait
helm upgrade -f ./base/cp-values.yaml kong kong/kong -n kong \
--set manager.ingress.hostname=$KONG_MANAGER_URI \
--set portal.ingress.hostname=$KONG__GUI_HOST \
--set admin.ingress.hostname=$KONG_ADMIN_API_URI \
--set portalapi.ingress.hostname=$KONG_PORTAL_API_URI --wait
watch "kubectl get pods -A"
http get $KONG_ADMIN_API_URL | jq .version


# KGLL-212-07.md

