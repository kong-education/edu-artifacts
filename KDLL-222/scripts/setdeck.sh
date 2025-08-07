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

# Validate CP
source ~/$KONG_COURSE_ID/setCP.sh

# Create CONFIG for decK
cat <<EOF> ~/.deck.yaml 
konnect-addr: https://us.api.konghq.com
konnect-token: $PAT
konnect-control-plane-name: "flights-team"
EOF
