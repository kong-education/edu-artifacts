#!/bin/bash

# "Kong Gateway Installation" Lesson (aka KGAC-202 content)

echo "This script will remove your data plane Kubernetes cluster (if there is one). Are you sure you want to continue? (Y/n)"
read response 

if [[ ! $response =~ ^[Yy]$ ]]
then
    echo exiting
    exit 1
fi
echo 
    
source /home/ubuntu/.envs

# Reset the environment
if [ "$(docker ps -q)" ] 
then 
    docker kill $(docker ps -q) > /dev/null 2>&1
    docker rm $(docker ps -a -q) > /dev/null 2>&1
fi
docker network prune -f > /dev/null 2>&1

kind delete cluster 

cp /home/ubuntu/.lab_vars /home/ubuntu/.lab_vars.BAK
echo "" > /home/ubuntu/.lab_vars

# rm -rf $COURSEDIR/*
clear
