#!/bin/bash

blk=$(tput -T screen setaf 0)
red=$(tput -T screen setaf 1)
grn=$(tput -T screen setaf 2)
ylw=$(tput -T screen setaf 3)
blu=$(tput -T screen setaf 4)
mag=$(tput -T screen setaf 5)
cyn=$(tput -T screen setaf 6)
wit=$(tput -T screen setaf 7)
nrm=$(tput -T screen sgr0)


# Wait for INIT script to complete
while [ ! -f /home/ubuntu/.initcomplete ] ; do sleep 1; done

# Initialise env variables
source /home/ubuntu/.envs

# Set Konnect API Endpoints
KAPI="https://us.api.konghq.com/v2"

VALIDATED=400
PATF="/home/ubuntu/$KONG_COURSE_ID/.pat"

while [ $VALIDATED -ne 200 ]; do
  # Check if the PAT file exists
  if [ -f $PATF ]; then
    PAT=$(<$PATF)
  else
    printf "\n\n${red}Valid saved PAT not found!${nrm}\n\n"
    printf "\n\n${grn}Please input existing PAT, or a new PAT created at https://cloud.konghq.com/global/account/tokens${nrm}\n\n"
    read PAT
    echo "$PAT" > $PATF 
  fi
  # Check if PAT is valid
  VALIDATED=$(https --headers GET $KAPI/runtime-groups \
                --auth-type=bearer \
                --auth=$PAT \
                | head -n 1 \
                | cut -d ' ' -f 2)
  [ $VALIDATED -ne 200 ] && rm $PATF
done

# Create CONFIG for HTTPie
mkdir -p ~/.config/httpie
cat <<EOF> ~/.config/httpie/config.json 
{
  "default_options": [
    "--verify=no",
    "--check-status",
    "--auth-type=bearer",
    "--auth=$PAT"
  ]
}
EOF