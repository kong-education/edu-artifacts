#!/bin/bash

# Plugins for Securing API Traffic on Konnect

source /home/ubuntu/.setup_common.sh

docker compose -f $COURSEDIR/docker-compose-keycloak.yaml up -d > /dev/null 2>&1 &

# Removing conf file as bearer token is getting passed when oidc plugin is enabled
if [ -f /home/ubuntu/.config/httpie/config.json ]; then
  mv /home/ubuntu/.config/httpie/config.json /home/ubuntu/.config/httpie/config.json.BAK
fi

source /home/ubuntu/.envs
source /home/ubuntu/.lab_vars
deck sync -s deck/bankong-base.yaml > /dev/null 2>&1

printf "\n${green}Completed Setting up Lab Environment.

You should remain in the directory '$COURSEDIR' unless instructions direct you otherwise.${normal}

${red}Please run the command 'source /home/ubuntu/.lab_vars' to set your environment variables.${normal}\n"

# This to check in class if/when this script was executed
# touch /home/ubuntu/"Finished_running_$(basename $0)" && $(date) >> $_
echo -e "Finished $(date)\n" >> /home/ubuntu/lab_setup.log

