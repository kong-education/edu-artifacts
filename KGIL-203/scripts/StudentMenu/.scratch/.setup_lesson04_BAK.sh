#!/bin/bash

# Using decK with Konnect

source /home/ubuntu/.envs

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

# ID=$(docker ps|grep kong-gateway|awk {'print $1'})
# docker stop $ID
# docker rm $ID

# Create ~/.pat if it doesnt exist
if [[ -n "$MYPAT" ]] 
then 
    echo "$MYPAT" >> /home/ubuntu/.pat
fi


cp $COURSEDIR/deck/.bankong-base.yaml.ForDockerDP $COURSEDIR/deck/bankong-base.yaml

source $COURSEDIR/setScriptConfig

export DECK_KONNECT_TOKEN=$(cat $PATFILE)
export MYPAT=$(cat $PATFILE)

"$COURSEDIR"/create_k8s_dataplane.sh

rm -f /home/ubuntu/.deck.yaml
# rm -f /home/ubuntu/.lab_files
 
# setup ~/.lab_files
echo "export MYPAT='$MYPAT'" >> /home/ubuntu/.lab_vars
CPID=$(https GET https://us.api.konghq.com/v2/control-planes --auth-type=bearer --auth=$MYPAT | jq -r '.data[] | select(.name == "training") | .id')
echo "export CPID='$CPID'" >> /home/ubuntu/.lab_vars
echo "export CPURL='https://us.api.konghq.com/v2/control-planes/$CPID'" >> /home/ubuntu/.lab_vars
source /home/ubuntu/.lab_vars

mkdir -p /home/ubuntu/.config/httpie
rm -f /home/ubuntu/.config/httpie/config.json 
cat <<EOF> /home/ubuntu/.config/httpie/config.json 
{
  "default_options": [
    "--verify=no",
    "--check-status",
    "--auth-type=bearer",
    "--auth=$MYPAT"
  ]
}
EOF

# rm -f /home/ubuntu/.config/httpie/config.json
# rm -rf $COURSEDIR/* $COURSEDIR/.* > /dev/null 2>&1

# printf "\n${green}Recreating Kubernetes cluster\n${normal}"
# kind delete cluster > /dev/null 2>&1
# kind create cluster --config kind.yaml > /dev/null 2>&1

# printf "\n${green}Checking Kubernetes cluster\n${normal}"
# kubectl get nodes

cd ~/$KONG_COURSE_ID
# clear
docker compose -f $COURSEDIR/docker-compose-bankong.yaml up -d  > /dev/null 2>&1

printf "\n${blue}Completed Setting up Lab Environment.${normal}\n"
