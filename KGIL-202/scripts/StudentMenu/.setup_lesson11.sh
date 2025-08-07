#!/bin/bash

# Troubleshooting

source /home/ubuntu/.envs
source $COURSEDIR/setScriptConfig

echo "This script will reset your control plane and replace your data plane Kubernetes cluster (if there is one). Are you sure you want to continue? (Y/n)"
read response 

if [[ ! $response =~ ^[Yy]$ ]]
then
    echo exiting
    exit 1
fi
echo 

# Reset the environment
if [ "$(docker ps -q)" ] 
then 
    docker kill $(docker ps -q) > /dev/null 2>&1
    docker rm $(docker ps -a -q) > /dev/null 2>&1
fi
docker network prune -f > /dev/null 2>&1
# rm -rf $COURSEDIR/* $COURSEDIR/.* > /dev/null 2>&1
kind delete cluster 

source $COURSEDIR/setPAT.sh

export MYPAT=$(cat $PATFILE)
export DECK_KONNECT_TOKEN=$(cat $PATFILE)

cat << EOF > /home/ubuntu/.deck.yaml 
konnect-addr: $KDOMAIN
konnect-token: $DECK_KONNECT_TOKEN
konnect-runtime-group-name: $CP_NAME
EOF

source $COURSEDIR/setRTI.sh

# The new soution uses /var/log/kong as the log directory.
# I don't want to change this at the moment. Let's fix it when we refactor this course.
mkdir -p /etc/kong/logs
chmod -R 777 /etc/kong/logs

# Run the Gateway
cp $COURSEDIR/docker-compose.yaml $COURSEDIR/troubleshooting/
docker compose -f $COURSEDIR/troubleshooting/docker-compose.yaml up -d

export RTGID=$(cat /home/ubuntu/$KONG_COURSE_ID/.rtgid)

mkdir -p  /home/ubuntu/.config/httpie
cat <<EOF> /home/ubuntu/.config/httpie/config.json 
{
  "default_options": [
    "--verify=no",
    "--check-status",
    "--auth-type=bearer",
    "--auth=$DECK_KONNECT_TOKEN"
  ]
}
EOF

export MYPAT=$DECK_KONNECT_TOKEN
echo "export MYPAT=$MYPAT" > /home/ubuntu/.lab_vars
export CPID=$(https GET https://us.api.konghq.com/v2/control-planes --auth-type=bearer --auth=$MYPAT | jq -r '.data[] | select(.name == "'$CP_NAME'") | .id')
echo "export CPID=$CPID" >> /home/ubuntu/.lab_vars
echo "export CPURL=https://us.api.konghq.com/v2/control-planes/$CPID" >> /home/ubuntu/.lab_vars

source /home/ubuntu/.envs
source /home/ubuntu/.lab_vars

cd $COURSEDIR

docker compose -f $COURSEDIR/docker-compose-bankong.yaml up -d  > /dev/null 2>&1

printf "\n${green}Completed Setting up Lab Environment.

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


