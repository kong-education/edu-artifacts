#!/bin/bash

# Designing & Testing APIs with Insomnia

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

kind delete cluster  > /dev/null 2>&1

cd ~/$KONG_COURSE_ID
# clear

# Copy KongAir files
mkdir -p "$COURSEDIR"/kongair
curl -fsSL https://raw.githubusercontent.com/kong-education/KongAir-for-developers/refs/heads/main/docker-compose.yaml -o "$COURSEDIR/kongair/docker-compose.yaml"

# This to check in class if/when this script was executed
# touch /home/ubuntu/"Finished_running_$(basename $0)" && $(date) >> $_
echo -e "Finished $(date)\n" >> /home/ubuntu/lab_setup.log

printf "\n${blue}Completed Setting up Lab Environment.${normal}\n"
