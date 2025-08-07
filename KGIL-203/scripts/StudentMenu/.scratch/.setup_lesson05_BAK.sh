#!/bin/bash

# Configuring API Products on Konnect

source /home/ubuntu/.envs
source $COURSEDIR/setScriptConfig

red=$(tput setaf 1)
green=$(tput setaf 2)
blue=$(tput setaf 4)
normal=$(tput sgr0)

# Reset the environment
if [ "$(docker ps -q)" ] 
then 
    docker kill $(docker ps -q) > /dev/null 2>&1
    docker rm $(docker ps -a -q) > /dev/null 2>&1
fi
docker network prune -f > /dev/null 2>&1
# rm -rf $COURSEDIR/* $COURSEDIR/.* > /dev/null 2>&1

docker compose -f $COURSEDIR/docker-compose-bankong.yaml up -d  > /dev/null 2>&1

export DECK_KONNECT_TOKEN=$(cat ~/.pat)
cat << EOF > ~/.deck.yaml 
konnect-addr: https://us.api.konghq.tech
konnect-token: $DECK_KONNECT_TOKEN
konnect-control-plane-name: training
EOF


$COURSEDIR/create_k8s_dataplane.sh

mkdir -p  ~/.config/httpie
cat <<EOF> ~/.config/httpie/config.json 
{
  "default_options": [
    "--verify=no",
    "--check-status",
    "--auth-type=bearer",
    "--auth=$DECK_KONNECT_TOKEN"
  ]
}
EOF

# kind delete cluster 

cd ~/$KONG_COURSE_ID
# clear

# Lesson lab setup smarts here


printf "\n${blue}Completed Setting up Lab Environment.${normal}\n"
