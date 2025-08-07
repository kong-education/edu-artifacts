#!/bin/bash

# Wait for INIT script to complete
while [ ! -f /home/ubuntu/.initcomplete ] ; do sleep 1; done

source setScriptConfig

# Validate PAT
source ~/$KONG_COURSE_ID/setPAT.sh

# Validate RTG
source ~/$KONG_COURSE_ID/setRTG.sh

# Create CONFIG for decK
cat <<EOF> ~/.deck.yaml 
konnect-addr: $KDOMAIN
konnect-token: $PAT
konnect-control-plane-name: "$CP_NAME"
EOF
