#!/bin/bash

# "Kong Gateway Installation" Lesson (aka KGAC-202 content)

source /home/ubuntu/.envs

# Reset the environment
if [ "$(docker ps -q)" ] 
then 
    docker kill $(docker ps -q) > /dev/null 2>&1
    docker rm $(docker ps -a -q) > /dev/null 2>&1
fi
docker network prune -f > /dev/null 2>&1
rm -rf $COURSEDIR/*
# clear
