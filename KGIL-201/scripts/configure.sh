#!/bin/bash

# Seems .profile wasn't getting read, so had to add this
# set PATH so it includes user's private bin if it exists
source ~/.envs

cd ~/$KONG_COURSE_ID

red=$(tput setaf 1)
green=$(tput setaf 2)
normal=$(tput sgr0)

printf "\n${green}Welcome to Kong Gateway Operations.${normal}\n"
printf "\n${green}Run 'setup' at any time (and select the appropriate option) to set up this virtual machine for a specific lesson or reset your lab. Then navigate to '$COURSEDIR' to proceed.${normal}\n\n"

