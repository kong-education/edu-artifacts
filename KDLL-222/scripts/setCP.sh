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
if https GET "$KAPI/control-planes" | jq -re '.data[].name | select(. == "flights-team")'; then
  printf "\n\n${grn}flights-team Control Plane exists.${nrm}\n\n"
  CPID=$(https GET $KAPI/control-planes | jq -r '.data[] | select(.name == "flights-team") .id') 
  https PATCH $KAPI/control-planes/$CPID auth_type=pinned_client_certs 
else
  printf "\n\n${red}flights-team Control Plane does not exist!${nrm}\n\n"
  printf "\n\n${grn}Creating flights-team Control Plane.${nrm}\n\n"
  https POST $KAPI/control-planes \
    name='flights-team' \
    description='Control Plane for flights-team' \
    cluster_type='CLUSTER_TYPE_HYBRID' \
    labels:='{"EDU":"true"}'  \
    auth_type=pinned_client_certs 
fi

# Get Control Plane ID
CPID=$(https GET $KAPI/control-planes | jq -r '.data[] | select(.name == "flights-team") .id') 
CPIDF="/home/ubuntu/$KONG_COURSE_ID/.cpid"
echo "$CPID" > $CPIDF

# Set Konnect API Endpoints
CP=$KAPI/control-planes/$CPID/core-entities
