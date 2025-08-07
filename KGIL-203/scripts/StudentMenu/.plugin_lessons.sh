#!/bin/bash

##############################################################################
# This is a hidden script to set the env up for the auxiliary plugin lessons #
##############################################################################

source /home/ubuntu/.envs
cd $COURSEDIR

red=$(tput setaf 1)
green=$(tput setaf 2)
blue=$(tput setaf 4)
normal=$(tput sgr0)
# clear
 
PS3='Please select the lesson you wish to set up: '
lessons=(
    "Plugins for API Traffic Control on Konnect"
    "Plugins for Securing API Traffic on Konnect"
    "Quit"
    )
COLUMNS=12

select opt in "${lessons[@]}"
do
    case $opt in
        "Plugins for Securing API Traffic on Konnect")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson06.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Plugins for API Traffic Control on Konnect")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson07.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

source /home/ubuntu/.lab_vars

# printf "\n${blue}VM configured. Navigate to '$COURSEDIR' to proceed .\n${normal}"
