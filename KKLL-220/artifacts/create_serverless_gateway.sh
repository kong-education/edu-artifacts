#!/bin/bash

source /home/ubuntu/.envs

export BLUE='\033[34m'
export GREEN='\033[32m'
export RED='\033[0;31m'
export YELLOW='\033[0;33m'
export AMBER='\033[38;5;214m'
export NC='\033[0m' # No Color

GEO="us"

if [ -z "$PAT" ]; then
    read -p "Enter your Personal Access Token (PAT): " PAT
fi

export PAT

echo $PAT > /home/ubuntu/.pat
export GATEWAY_NAME="$KONG_COURSE_ID-Gateway"
export GATEWAY_DESCRIPTION="$KONG_COURSE_ID Gateway"
export DECK_GATEWAY_NAME=$GATEWAY_NAME # Req'd for deck
BASEDECKFILE_LOC=/home/ubuntu/$KONG_COURSE_ID/deck_base

# Create the control plane
printf "${BLUE}Creating the control plane '$GATEWAY_NAME'...${NC}\n"
curl -s -o /dev/null --request POST \
  --url https://$GEO.api.konghq.com/v2/control-planes \
  --header 'Accept: application/json, application/problem+json' \
  --header "Authorization: Bearer $PAT" \
  --header 'Content-Type: application/json' \
  --data '{
  "name": "'"$GATEWAY_NAME"'",
  "description": "'"$GATEWAY_DESCRIPTION"'",
  "cluster_type": "CLUSTER_TYPE_SERVERLESS",
  "cloud_gateway": false,
  "labels": {"course": "'"$KONG_COURSE_ID"'"}
  }'

sleep 3

export CONTROL_PLANE_ID=$(curl -s -X GET https://"$GEO".api.konghq.com/v2/control-planes -H "Authorization: Bearer $PAT" | jq -r --arg gw "$GATEWAY_NAME" '.data[] | select(.name == $gw) | .id')

# Create the data plane
printf "${BLUE}Creating the data plane...${NC}\n"

curl -s -o /dev/null -X PUT "https://global.api.konghq.com/v3/cloud-gateways/configurations" \
    -H "Accept: application/json"\
    -H "Content-Type: application/json"\
    -H "Authorization: Bearer $PAT" \
    --data '{
      "control_plane_id":  "'"$CONTROL_PLANE_ID"'",
      "control_plane_geo": "us",
      "dataplane_groups": [
        {
          "region": "na"
        }
      ],
      "kind": "serverless.v0"
    }'


while true; do
  STATE=$(curl -s -X GET "https://global.api.konghq.com/v3/cloud-gateways/configurations" \
    -H "Authorization: Bearer $PAT" \
    -H "Content-Type: application/json" \
    | jq -r --arg CP_ID "$CONTROL_PLANE_ID" '.data[] | select(.control_plane_id == $CP_ID) | .dataplane_groups[].state')

  if [[ "$STATE" == "ready" ]]; then
    printf "${GREEN}Proxy is ready${NC}\n"
    break
  elif [[ "$STATE" == "null" || -z "$STATE" ]]; then
    printf "${AMBER}Proxy is still initializing...${NC}\n"
  else
    printf "${AMBER}Initializing...${NC}\n"
  fi

  sleep 5 
done

# Fetch proxy_url
PROXY_URL=$(curl -s -X GET "https://global.api.konghq.com/v3/cloud-gateways/configurations" \
  -H "Authorization: Bearer $PAT" \
  | jq -r --arg CP_ID "$CONTROL_PLANE_ID" '.data[] | select(.control_plane_id == $CP_ID) | .dataplane_groups[].hostnames[]')


cat <<EOF >> /home/ubuntu/.envs
export PROXY_URL="$PROXY_URL"
export PAT=$(cat /home/ubuntu/.pat)
export DECK_GATEWAY_NAME=$DECK_GATEWAY_NAME
EOF
source /home/ubuntu/.envs

cat <<EOF> /home/ubuntu/.deck.yaml 
konnect-addr: https://us.api.konghq.com
konnect-token: $PAT
konnect-control-plane-name: $GATEWAY_NAME
EOF

printf "${GREEN}Deploying routes, and consumers for KongAir using 'deck'${NC}\n\n"

deck gateway sync $BASEDECKFILE_LOC > /dev/null 2>&1

printf "System is ready. Your Proxy URL is: ${BLUE}https://$PROXY_URL${NC}\n\n"


## In case we want to run KongAir locally
# curl -fsSL https://raw.githubusercontent.com/kong-education/KongAir/main/docker-compose.yaml -o "KongAir-compose.yaml"
# docker compose -f KongAir-compose.yaml up -d # > /dev/null 2>&1

# #Install StatsD and Prometheus
# kubectl create namespace monitoring
# helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
# helm repo add grafana https://grafana.github.io/helm-charts
# helm repo update

# echo "Installing Monitoring Tools..."
# helm install -f $COURSEDIR/artifacts/monitoring/prometheus-values.yaml prometheus prometheus-community/kube-prometheus-stack -n monitoring --wait 
# helm install -f $COURSEDIR/artifacts/monitoring/statsd-values.yaml statsd prometheus-community/prometheus-statsd-exporter -n monitoring --wait
# helm install -f artifacts/monitoring/grafana-values.yaml grafana grafana/grafana -n monitoring --wait >> /dev/null 2>&1

# # rm  ~/.config/httpie/config.json
# mkdir -p  ~/.config/httpie
# cat <<EOF> ~/.config/httpie/config.json 
# {
#   "default_options": [
#     "--verify=no",
#     "--check-status",
#     "--auth-type=bearer",
#     "--auth=$PAT"
#   ]
# }
# EOF