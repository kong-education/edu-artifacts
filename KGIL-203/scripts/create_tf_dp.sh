#!/bin/bash

source /home/ubuntu/.lab_vars
TFSTATE_FILE="$COURSEDIR/terraform/terraform.tfstate"

# Extract Variables from Terraform State
export CPID=$(jq -r '.resources[] | select(.type == "konnect_gateway_control_plane") | .instances[0].attributes.id' $TFSTATE_FILE)
KONG_CLUSTER_CONTROL_PLANE=$(jq -r '.resources[] | select(.type == "konnect_gateway_control_plane") | .instances[0].attributes.config.control_plane_endpoint' $TFSTATE_FILE)
KONG_CLUSTER_TELEMETRY_ENDPOINT=$(jq -r '.resources[] | select(.type == "konnect_gateway_control_plane") | .instances[0].attributes.config.telemetry_endpoint' $TFSTATE_FILE)

# Remove the https:// part from the variables
export KONG_CLUSTER_CONTROL_PLANE=${KONG_CLUSTER_CONTROL_PLANE#https://}
export KONG_CLUSTER_TELEMETRY_ENDPOINT=${KONG_CLUSTER_TELEMETRY_ENDPOINT#https://}

echo "export CPID=$CPID" >> /home/ubuntu/.lab_vars
echo "export CPURL=https://us.api.konghq.com/v2/control-planes/$CPID" >> /home/ubuntu/.lab_vars
echo "export KONG_CLUSTER_CONTROL_PLANE=$KONG_CLUSTER_CONTROL_PLANE" >> /home/ubuntu/.lab_vars
echo "export KONG_CLUSTER_TELEMETRY_ENDPOINT=$KONG_CLUSTER_TELEMETRY_ENDPOINT" >> /home/ubuntu/.lab_vars
source /home/ubuntu/.lab_vars
# Pin DP client cert
CLUSTER_CERT=$(cat /etc/kong/ssl/cluster.crt)

https POST $CPURL/dp-client-certificates cert="$CLUSTER_CERT" --auth-type=bearer --auth=$MYPAT > /dev/null 2>&1

docker-compose -f "$COURSEDIR/docker-compose.yaml" up -d
