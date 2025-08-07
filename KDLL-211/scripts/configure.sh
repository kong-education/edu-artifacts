#!/bin/bash

green=$(tput setaf 2)
blue=$(tput setaf 4)
normal=$(tput sgr0)


source ~/.envs
cd ~/$KONG_COURSE_ID

clear

printf "\n${green}Bringing up Kong Gateway.${normal}\n"
docker compose up -d
printf "\n${blue}Waiting for Gateway startup to finish.${normal}\n"

until curl --head localhost:8001 > /dev/null 2>&1; do 
    sleep 1;
done

printf "\n${blue}Gateway is running. Deploying routes and services.${normal}\n"

deck sync -s deck/bankong-base.yaml

printf "\n${green}Completed Setting up Lab Environment.\n${normal}"
