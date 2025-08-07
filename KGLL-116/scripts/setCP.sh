#!/bin/bash

# Set Color Codes
blk=$(tput -T screen setaf 0)
red=$(tput -T screen setaf 1)
grn=$(tput -T screen setaf 2)
ylw=$(tput -T screen setaf 3)
blu=$(tput -T screen setaf 4)
mag=$(tput -T screen setaf 5)
cyn=$(tput -T screen setaf 6)
wit=$(tput -T screen setaf 7)
nrm=$(tput -T screen sgr0)

# Set Konnect API Endpoints
KAPI="https://us.api.konghq.com/v2"

# Wait for INIT script to complete
while [ ! -f /home/ubuntu/.initcomplete ] ; do sleep 1; done

# Initialise env variables
source ~/.envs

# Validate PAT
source ~/$KONG_COURSE_ID/setPAT.sh

# Determine if training RTG is present
if https GET "$KAPI/runtime-groups" | jq -re '.data[].name | select(. == "training")'; then
  printf "\n\n${grn}RTG training exists.${nrm}\n\n"
else
  printf "\n\n${red}RTG training does not exist!${nrm}\n\n"
  printf "\n\n${grn}Creating RTG training.${nrm}\n\n"
  https POST $KAPI/runtime-groups \
  name='training' \
  description='RTG for training LP' \
  cluster_type='CLUSTER_TYPE_HYBRID' \
  labels:='{"EDU":"true"}'  
fi

# Get RTG ID
RTGID=$(https GET $KAPI/runtime-groups | jq -r '.data[] | select(.name == "training") .id') 
RTGIDF="/home/ubuntu/$KONG_COURSE_ID/.rtgid"
echo "$RTGID" > $RTGIDF