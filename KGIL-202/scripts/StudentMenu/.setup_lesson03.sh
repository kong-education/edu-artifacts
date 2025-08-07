#!/bin/bash

# Using Kong Operator 

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
# rm -rf $COURSEDIR/* $COURSEDIR/.* > /dev/null 2>&1

kind delete cluster  > /dev/null 2>&1

# Create new cluster
kind create cluster --config=/home/ubuntu/$KONG_COURSE_ID/KinD.yaml

source /home/ubuntu/.envs

# # Install Gateway API resources
# kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

cd ~/$KONG_COURSE_ID
# source /home/ubuntu/$KONG_COURSE_ID/deploy-kic.sh

# kubectl -n kong apply -f /home/ubuntu/$KONG_COURSE_ID/kongair/flights-service.yaml

# clear

# This to check in class if/when this script was executed
# touch /home/ubuntu/"Finished_running_$(basename $0)" && $(date) >> $_
echo -e "Finished $(date)\n" >> /home/ubuntu/lab_setup.log

printf "\n${blue}Completed Setting up Lab Environment.${normal}\n"
