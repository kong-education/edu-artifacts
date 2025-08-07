#!/bin/bash

logger -i -p info -t STRIGO "Running setPAT script."
# Wait for INIT script to complete
while [ ! -f /home/ubuntu/.initcomplete ] ; do sleep 1; done

source /home/ubuntu/$KONG_COURSE_ID/setScriptConfig

# blk=$(tput -T screen setaf 0)
# red=$(tput -T screen setaf 1)
# grn=$(tput -T screen setaf 2)
# ylw=$(tput -T screen setaf 3)
# blu=$(tput -T screen setaf 4)
# mag=$(tput -T screen setaf 5)
# cyn=$(tput -T screen setaf 6)
# wit=$(tput -T screen setaf 7)
# nrm=$(tput -T screen sgr0)


# Initialise env variables
# source /home/ubuntu/.envs

# Set Konnect API Endpoints
# KAPI="https://us.api.konghq.com/v2"

VALIDATED=400
# PATFILE="/home/ubuntu/$KONG_COURSE_ID/.pat"

while [ $VALIDATED -ne 200 ]; do
  # Check if the PAT file exists
  if [ -s $PATFILE ]; then
    PAT=$(cat $PATFILE)
  else
    printf "\n\n${red}Valid saved PAT not found!${nrm}\n\n"
    printf "${grn}Please input existing PAT, or a new PAT created at https://cloud.konghq.com/global/account/tokens${nrm}\n\n"
    read PAT
    echo "$PAT" > $PATFILE 
  fi
  # Check if PAT is valid
  VALIDATED=$(https --headers GET $KAPI/runtime-groups \
                --auth-type=bearer \
                --auth=$PAT \
                | head -n 1 \
                | cut -d ' ' -f 2)
  [ $VALIDATED -ne 200 ] && rm $PATFILE
  # echo "export MYPAT='kpat_6BHxuYSuodrvhnIa232ZPKEI44silOi2Yl6sicvFSY1Gf0MVB'" >> ~/.lab_vars

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