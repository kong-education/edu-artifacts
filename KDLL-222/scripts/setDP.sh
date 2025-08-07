#!/bin/bash

# Set Color Codes
blk=$(tput -T screen setaf 0)
red=$(tput -T screen setaf 1)
grn=$(tput -T screen setaf 2)
ylw=$(tput -T screen setaf 3)
blu=$(tput -T screen setaf 4)
mag=$(tput -T screen setaf 5)
cyn=$(tput -T screen setaf 6)
wit=$(tput -T screen setaf 7)
nrm=$(tput -T screen sgr0)

# Set Konnect API Endpoints
KAPI="https://us.api.konghq.com/v2"

# Wait for INIT script to complete
while [ ! -f /home/ubuntu/.initcomplete ] ; do sleep 1; done

# Initialise env variables
source ~/.envs

# Validate PAT
source ~/$KONG_COURSE_ID/setPAT.sh

# Validate RTG
source ~/$KONG_COURSE_ID/setCP.sh

KONG_CLUSTER_CONTROL_PLANE=$(https GET $KAPI/control-planes \
  | jq -r '.data[] | select(.name == "flights-team") .config.control_plane_endpoint' \
  | cut -c 9-)

KONG_CLUSTER_TELEMETRY_ENDPOINT=$(https GET $KAPI/control-planes \
  | jq -r '.data[] | select(.name == "flights-team") .config.telemetry_endpoint' \
  | cut -c 9-)

# Pin DP client cert
CK=$(cat /etc/kong/ssl/cluster.crt)
CC=$(http GET "$KAPI/control-planes/$CPID/dp-client-certificates" | jq '.items[] | select(.metadata.issuer == "CN=kong_clustering") .cert')
if [ -z "$CC" ] ; then
  printf "\n\n${red}DP CLient Cert does not exist!${nrm}\n\n"
  printf "\n\n${grn}Creating DP CLient Cert.${nrm}\n\n"
  http POST $KAPI/control-planes/$CPID/dp-client-certificates cert="$CK"
else
  printf "\n\n${grn}DP CLient Cert exists.${nrm}\n\n" 
fi

# Create compose file for DP
cat <<EOF> ~/$KONG_COURSE_ID/docker-compose.yaml
services:

  konnect-dp:
    image: kong/kong-gateway:3.4
    container_name: konnect-dp
    hostname: konnect-dp
    networks:
      - kong-edu-net
    environment:
      KONG_ROLE: "data_plane"
      KONG_DATABASE: "off"
      KONG_CLUSTER_MTLS: "pki"
      KONG_CLUSTER_CONTROL_PLANE: "$KONG_CLUSTER_CONTROL_PLANE:443"
      KONG_CLUSTER_SERVER_NAME: "$KONG_CLUSTER_CONTROL_PLANE"
      KONG_CLUSTER_TELEMETRY_ENDPOINT: "$KONG_CLUSTER_TELEMETRY_ENDPOINT:443"
      KONG_CLUSTER_TELEMETRY_SERVER_NAME: "$KONG_CLUSTER_TELEMETRY_ENDPOINT"
      KONG_CLUSTER_CERT: /var/kong/certs/cluster.crt
      KONG_CLUSTER_CERT_KEY: /var/kong/certs/cluster.key
      KONG_SSL_CERT: /var/kong/certs/server.crt
      KONG_SSL_CERT_KEY: /var/kong/certs/server.key
      KONG_LUA_SSL_TRUSTED_CERTIFICATE: system
      KONG_VITALS: "off"
      KONG_KONNECT_MODE: "on"
      KONG_CLUSTER_DP_LABELS: "type:docker-linuxdockerOS"
    volumes:
      - /etc/kong/ssl:/var/kong/certs
    ports:
      - "8000:8000/tcp"
      - "8443:8443/tcp"

networks:
  kong-edu-net:
    name: kong-edu-net
    driver: bridge
    external: true
EOF

docker ps | grep "kong/kong-gateway" | awk '{print $1}' | xargs docker kill > /dev/null 2>&1
docker compose up -d
