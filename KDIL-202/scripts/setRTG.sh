#!/bin/bash

logger -i -p info -t STRIGO "Start process for creating a new Konnect Control Plane"
# Wait for INIT script to complete
while [ ! -f /home/ubuntu/.initcomplete ] ; do sleep 1; done

# source setScriptConfig
source /home/ubuntu/$KONG_COURSE_ID/setScriptConfig

# Initialise env variables
# source ~/.envs
source $COURSEDIR/setScriptConfig

# Validate PAT
source /home/ubuntu/$KONG_COURSE_ID/setPAT.sh

# If "training" control plane already exists, delete it. 

CP=$(https GET "$KAPI/runtime-groups" | jq --arg CP_NAME "$CP_NAME" '.data[] | select(.name == $CP_NAME)')
CP_ID=$(echo $CP | jq -r '.id')
if [ "$CP" ] ; then
  logger -i -p info -t STRIGO "$CP_NAME Control Plane already exists. Deleting it."
  https DELETE "$KAPI/runtime-groups/$CP_ID" > /dev/null 2>&1
fi

# Create Control Plane
logger -i -p info -t STRIGO "Creating "$CP_NAME" Konnect Control Plane"
printf "\n\n${grn}Creating $CP_NAME Control Plane.${nrm}\n\n"
https POST $KAPI/runtime-groups \
  name="$CP_NAME" \
  description="Training control plane" \
  cluster_type='CLUSTER_TYPE_HYBRID' \
  labels:='{"EDU":"true"}' > /dev/null 2>&1

# Get  id for newly created Control Plane
export RTGID=$(https GET $KAPI/runtime-groups | jq -r '.data[] | select(.name == "'$CP_NAME'") .id') 
export RTGIDF="/home/ubuntu/$KONG_COURSE_ID/.rtgid"
echo "$RTGID" > $RTGIDF