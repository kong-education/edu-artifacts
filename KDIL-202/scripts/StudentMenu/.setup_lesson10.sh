#!/bin/bash

# Group Assignment

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
curl -fsSL https://raw.githubusercontent.com/kong-education/KongAir-for-developers/refs/heads/main/docker-compose.yaml -o "$COURSEDIR/kongair/docker-compose.yaml" > /dev/null 2>&1
# Start KongAir

# Get assignment files

mkdir -p "$COURSEDIR/project"
pushd "$COURSEDIR/project" &> /dev/null
git clone https://github.com/kong-education/edu-student-assignments.git > /dev/null 2>&1
# Move contents of the cloned repository to the current directory
mv edu-student-assignments/konnect_for_developers/* . > /dev/null 2>&1
# Remove the cloned repository folder
rm -rf edu-student-assignments > /dev/null 2>&1
# Remove Git-related files
popd &> /dev/null


docker compose -f "$COURSEDIR"/kongair/docker-compose.yaml up -d



echo -e "Finished $(date)\n" >> /home/ubuntu/lab_setup.log

printf "\n${blue}Completed Setting up Lab Environment.${normal}\n"
