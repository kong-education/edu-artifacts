#!/bin/bash

# Using decK with Konnect

source /home/ubuntu/.setup_common.sh

# rm -f /home/ubuntu/.deck.yaml 
cat << EOF > ~/.deck.yaml 
konnect-addr: https://us.api.konghq.com
konnect-token: $(cat ~/.pat)
konnect-control-plane-name: training
EOF


source /home/ubuntu/.lab_vars

printf "\n${green}Completed Setting up Lab Environment.

You should remain in the directory '$COURSEDIR' unless instructions direct you otherwise.${normal}

${red}Please run the command 'source /home/ubuntu/.lab_vars' to set your environment variables.${normal}\n"


# This to check in class if/when this script was executed
# touch /home/ubuntu/"Finished_running_$(basename $0)" && $(date) >> $_
echo -e "Finished $(date)\n" >> /home/ubuntu/lab_setup.log


