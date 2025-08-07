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
    "Install Kong Gateway on Konnect"
    "Extending Konnect Functionality with Plugins"
    "Designing & Testing APIs with Insomnia"
    "Using decK with Konnect"
    "Kong API Extensions and OpenAPI Spec"
    "Konnect Terraform Provider"
    "Configuring API Products on Konnect"
    "Developer Portal Operations"
    "Konnect Observability"
    "Group Assignment"
    "Reset Virtual Machine"
    "Quit"
    )
COLUMNS=12

select opt in "${lessons[@]}"
do
    case $opt in
        "Install Kong Gateway on Konnect")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson01.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Extending Konnect Functionality with Plugins")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson02.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Designing & Testing APIs with Insomnia")
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
        "Kong API Extensions and OpenAPI Spec")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson05.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Konnect Terraform Provider")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson06.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Configuring API Products on Konnect")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson07.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Developer Portal Operations")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson08.sh
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
        "Group Assignment")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson10.sh
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
