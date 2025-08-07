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
    "KIC Installation and Upgrade"
    "KIC Operations"
    "Using Kong Operator"
    "Advanced Plugins"
    "Advanced Usage"
    "Troubleshooting"
    "Reset Virtual Machine"
    "Quit"
    )
COLUMNS=12

select opt in "${lessons[@]}"
do
    case $opt in
        "KIC Installation and Upgrade")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson01.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "KIC Operations")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson02.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Using Kong Operator")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson03.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Using Deck with KIC")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson04.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Creating APIOps Pipelines")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson06.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Securing Services on Kong")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson07.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Advanced Plugins")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson08.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "OIDC Plugin")
            printf "\n${green}Setting up for 'lesson $REPLY $opt'\n${normal}"
            echo "Setting up for lesson '$opt' at $(date)" >> /home/ubuntu/lab_setup.log
            sleep 1
            . /home/ubuntu/.setup_lesson09.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Konnect Advanced Analytics")
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

source /home/ubuntu/.envs

# printf "\n${blue}VM configured. Navigate to '$COURSEDIR' to proceed .\n${normal}"
