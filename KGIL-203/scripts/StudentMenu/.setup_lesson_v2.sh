#!/bin/bash

source /home/ubuntu/.envs
cd $COURSEDIR

red=$(tput setaf 1)
green=$(tput setaf 2)
blue=$(tput setaf 4)
normal=$(tput sgr0)
# clear

PS3='Please select the lesson you wish to set up: '
lessons=(
    "Konnect Platform Architecture"
    "Install Kong Gateway on Konnect"
    "Using Admin API with Konnect"
    "Using decK with Konnect"
    "Extending Konnect Functionality with Plugins"
    "Productizing APIs on Konnect"
    "Konnect Observability"
    "Konnect User and Team Management"
    "Troubleshooting"
    "Reset Virtual Machine"
    "Quit"
    )
COLUMNS=12

select opt in "${lessons[@]}"
do
    case $opt in
        "Konnect Platform Architecture")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson01.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Install Kong Gateway on Konnect")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson02.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Using Admin API with Konnect")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson03.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Using decK with Konnect")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson04.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Extending Konnect Functionality with Plugins")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_Extending_Konnect_Functionality_with_Plugins.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Productizing APIs on Konnect")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson05.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Konnect Observability")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson09.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Konnect User and Team Management")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson10.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Troubleshooting")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson11.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Reset Virtual Machine")
            echo "Running script for '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            printf "\n${green}Resetting the environment.\n${normal}"
            . /home/ubuntu/.reset_lab.sh
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
