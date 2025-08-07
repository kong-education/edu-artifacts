#!/bin/bash

# Konnect User and Team Management

source /home/ubuntu/.setup_common.sh

source /home/ubuntu/.envs
source /home/ubuntu/.lab_vars
deck sync -s deck/bankong-base.yaml > /dev/null 2>&1

printf "\n${green}Completed Setting up Lab Environment.


cd ~/$KONG_COURSE_ID
source $COURSEDIR/setRTI.sh
cp $COURSEDIR/docker-compose.yaml $COURSEDIR/troubleshooting/
docker compose -f $COURSEDIR/troubleshooting/docker-compose.yaml up -d
cd $COURSEDIR/troubleshooting/
# clear
=======
You should remain in the directory '$COURSEDIR' unless instructions direct you otherwise.${normal}


${red}Please run the command 'source /home/ubuntu/.lab_vars' to set your environment variables.${normal}\n"

# We need to reset the original docker compose file
cat <<'EOF'> ~/$KONG_COURSE_ID/docker-compose.yaml
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
      KONG_LUA_SSL_TRUSTED_CERTIFICATE: system
    volumes:
      - /etc/kong/ssl:/var/kong/certs
    ports:
      - "8000:8000/tcp"
      - "8443:8443/tcp"

networks:
  kong-konnect:
    name: kong-konnect
EOF
# This to check in class if/when this script was executed
# touch /home/ubuntu/"Finished_running_$(basename $0)" && $(date) >> $_
echo -e "Finished $(date)\n" >> /home/ubuntu/lab_setup.log
