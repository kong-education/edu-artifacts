#!/bin/bash

# TTY Colors
blk=$(tput -T screen setaf 0)
red=$(tput -T screen setaf 1)
grn=$(tput -T screen setaf 2)
ylw=$(tput -T screen setaf 3)
blu=$(tput -T screen setaf 4)
mag=$(tput -T screen setaf 5)
cyn=$(tput -T screen setaf 6)
wit=$(tput -T screen setaf 7)
nrm=$(tput -T screen sgr0)

# ENV Variables
ENVF="/home/ubuntu/.envs"
source $ENVF
cd /home/ubuntu/$KONG_COURSE_ID

# PostOp Jobs

## Job 1
printf "\n\n${ylw}Deploying the Mesh...${nrm}\n\n"
source deploy.Mesh.sh

## Job 2
printf "\n\n${ylw}Deploying the Marketplace Demo App...${nrm}\n\n"
source deploy.App.sh

## Job 3
printf "\n\n${ylw}Deploying the KIC...${nrm}\n\n"
source deploy.KIC.sh

printf "\n\n${grn}All Done!\n\n${nrm}"
