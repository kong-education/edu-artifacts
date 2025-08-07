#!/bin/bash

# Using Konnect API 

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

cp $COURSEDIR/deck/.bankong-base.yaml.ForDockerDP $COURSEDIR/deck/bankong-base.yaml

source $COURSEDIR/setScriptConfig

rm -f /home/ubuntu/.deck.yaml
rm -f /home/ubuntu/.config/httpie/config.json
# rm -rf $COURSEDIR/* $COURSEDIR/.* > /dev/null 2>&1

# printf "\n${green}Recreating Kubernetes cluster\n${normal}"
kind delete cluster > /dev/null 2>&1
# kind create cluster --config kind.yaml > /dev/null 2>&1

# printf "\n${green}Checking Kubernetes cluster\n${normal}"
# kubectl get nodes

cd ~/$KONG_COURSE_ID
# clear
docker compose -f $COURSEDIR/docker-compose-bankong.yaml up -d  > /dev/null 2>&1

# This to check in class if/when this script was executed
# touch /home/ubuntu/"Finished_running_$(basename $0)" && $(date) >> $_
echo -e "Finished $(date)\n" >> /home/ubuntu/lab_setup.log

printf "\n${blue}Completed Setting up Lab Environment.${normal}\n"
