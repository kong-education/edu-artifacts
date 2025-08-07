#!/bin/bash

# Seems .profile wasn't getting read, so had to add this
# set PATH so it includes user's private bin if it exists
source ~/.envs
cd ~/$KONG_COURSE_ID

red=$(tput setaf 1)
green=$(tput setaf 2)
normal=$(tput sgr0)

# printf "\n${green}Welcome to Kong Gateway Operations for Konnect.

# Starting BanKonG sample banking application.${normal}\n"

# docker compose -f docker-compose-bankong.yaml up -d 

printf "\n${green}Welcome to Kong Gateway Operations for Konnect.

You should remain in the directory '$COURSEDIR' unless instructions direct you otherwise.${normal}\n\n"

printf "\n${green}Run 'setup' at any time (and select the appropriate option) to set up this virtual machine for a specific lesson or reset your lab. ${normal}\n\n"

tput sgr0

echo -e "Script '/home/ubuntu/start_lab.sh' executed at $(date)\n" >> /home/ubuntu/lab_setup.log

setup