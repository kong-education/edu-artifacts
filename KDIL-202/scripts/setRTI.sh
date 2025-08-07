#!/bin/bash

# Wait for INIT script to complete
while [ ! -f /home/ubuntu/.initcomplete ] ; do sleep 1; done

source setScriptConfig

# # Set Color Codes
# blk=$(tput -T screen setaf 0)
# red=$(tput -T screen setaf 1)
# grn=$(tput -T screen setaf 2)
# ylw=$(tput -T screen setaf 3)
# blu=$(tput -T screen setaf 4)
# mag=$(tput -T screen setaf 5)
# cyn=$(tput -T screen setaf 6)
# wit=$(tput -T screen setaf 7)
# nrm=$(tput -T screen sgr0)

# # Set Konnect API Endpoints
# KAPI="https://us.api.konghq.com/v2"


# Initialise env variables
# source ~/.envs

# Validate PAT
source ~/$KONG_COURSE_ID/setPAT.sh

# Validate RTG
source ~/$KONG_COURSE_ID/setRTG.sh

KONG_CLUSTER_CONTROL_PLANE=$(https GET $KAPI/runtime-groups \
  | jq -r '.data[] | select(.name == "'$CP_NAME'") .config.control_plane_endpoint' \
  | cut -c 9-)

KONG_CLUSTER_TELEMETRY_ENDPOINT=$(https GET $KAPI/runtime-groups \
  | jq -r '.data[] | select(.name == "'$CP_NAME'") .config.telemetry_endpoint' \
  | cut -c 9-)

# Pin DP client cert
CK=$(cat /etc/kong/ssl/cluster.crt)
https POST $KAPI/runtime-groups/$RTGID/dp-client-certificates cert="$CK" > /dev/null 2>&1

# Create compose file for RTI
cat <<EOF> ~/$KONG_COURSE_ID/docker-compose.yaml
version: "3"

volumes:
  kong_data: {}

services:

  konnect-dp:
    image: docker.io/kong/kong-gateway:3.4
    container_name: konnect-dp
    hostname: konnect-dp
    networks:
      - kong-konnect
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
      KONG_STREAM_LISTEN: "0.0.0.0:5555, 0.0.0.0:5556 ssl reuseport backlog=65536"
      KONG_STATUS_LISTEN: "0.0.0.0:8100"
      KONG_PROXY_ACCESS_LOG: /var/kong/logs/proxy_access.log
      KONG_PROXY_ERROR_LOG: /var/kong/logs/proxy_error.log
      KONG_PROXY_STREAM_ACCESS_LOG: /var/kong/logs/proxystream_access.log basic
      KONG_PROXY_STREAM_ERROR_LOG: /var/kong/logs/proxystream_error.log
      KONG_TRACING: "on"
      KONG_ALLOW_DEBUG_HEADER: "on"
      KONG_TRACING_WRITING_STRATEGY: "file"
      KONG_TRACING_TYPES: "all"
      KONG_TRACING_TIME_THRESHOLD: 0
      KONG_TRACING_WRITE_ENDPOINT: /var/kong/logs/granular_tracing.log
      KONG_TRACING_DEBUG_HEADER: X-Trace
    volumes:
      - /etc/kong/ssl:/var/kong/certs
      - /etc/kong/logs:/var/kong/logs 
    ports:
      - "8000:8000/tcp"
      - "8443:8443/tcp"
      - "8100:8100/tcp"

networks:
  kong-konnect:
    name: kong-konnect
    driver: bridge
EOF