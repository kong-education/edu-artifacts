#!/bin/bash
 
source /home/ubuntu/.envs

# set -x
# Make note of course ID as we need to change the identity for a bit later
ILT_COURSE_ID=$KONG_COURSE_ID

red=$(tput setaf 1)
green=$(tput setaf 2)
blue=$(tput setaf 4)
normal=$(tput sgr0)
# clear
 
config_lab() {

    echo "Setting up for lesson '$1' at $(date)" >> /home/ubuntu/.lab_setup.log

    #################################################################
    # Change the identity of the lab env to match the source lesson #
    #################################################################
    cp /home/ubuntu/.envs /home/ubuntu/.envs.BAK
    sed -i '/KONG_COURSE_ID/d' /home/ubuntu/.envs
    echo "export KONG_COURSE_ID=$1" >> /home/ubuntu/.envs
    # set +x
    source /home/ubuntu/.envs
    # set -x

    #################
    # Reset the lab #
    #################
    source /home/ubuntu/.reset_lab.sh

    ################################
    # Setup the lab for the course #
    ################################
    cp -R /home/ubuntu/.sources/$KONG_COURSE_ID/scripts/* /home/ubuntu/ #check this
    source /home/ubuntu/startup.sh # need to speak to john about this

    # [ -x /home/ubuntu/post_startup.sh ] && source /home/ubuntu/post_startup.sh
    if [ -x /home/ubuntu/post_startup.sh ]; then
        source /home/ubuntu/post_startup.sh
    else
        echo "debug: The script does not exist or is not executable."
    fi
  

    ################################################################
    # Move like '/home/ubuntu/KGLL-202' to '/home/ubuntu/KGIL-201' #
    ################################################################
    rm -rf /home/ubuntu/$ILT_COURSE_ID/*
    mkdir -p /home/ubuntu/$ILT_COURSE_ID # In case its got deleted
    cp -R /home/ubuntu/$1/* /home/ubuntu/$ILT_COURSE_ID/
    rm -f /home/ubuntu/$ILT_COURSE_ID/*sh
    rm -rf /home/ubuntu/$1

    ###########################################
    # Reset the lab identity back to KGIL-201 #
    ###########################################
    unset KONG_COURSE_ID
    cp /home/ubuntu/.envs.BAK /home/ubuntu/.envs
    # set +x
    source /home/ubuntu/.envs
    # set -x
    cd /home/ubuntu/$KONG_COURSE_ID
}

sub_menu() {

    echo ""
    PS3='Which Observability exercise would you like to do: '
sub_lessons=(
    "KDLL-217 - Monitoring APIs with Prometheus Plugin, Grafana and decK"
    "KDLL-218 - Logging API Traffic with File Log Plugin and decK"
    "KDLL-223 - Tracing APIs with the OpenTelemetry Plugin"
)

COLUMNS=12
select opt in "${sub_lessons[@]}"
do
    case $opt in
        "KDLL-216 - Connecting API Requests with Correlation ID Plugin and decK")
            echo KDLL-216
            exit 0
            ;;
        "KDLL-217 - Monitoring APIs with Prometheus Plugin, Grafana and decK")
            echo KDLL-217"
            exit 0
            ;;
        "KDLL-218 - Logging API Traffic with File Log Plugin and decK")
            echo KDLL-218"
            exit 0
            ;;
        "KDLL-219 - Logging API Traffic with TCP Log Plugin & Splunk and decK")
            echo KDLL-219"
            exit 0
            ;;
        "KDLL-223 - Tracing APIs with the OpenTelemetry Plugin")
            echo KDLL-223"
            exit 0
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
}

touch /home/ubuntu/.lab_setup.log
chmod a+w /home/ubuntu/.lab_setup.log

cd /home/ubuntu
echo ""
PS3='Please select the lesson you wish to set up: '
lessons=(
        "Kong Gateway Installation"
        "Upgrading Kong Gateway"
        "Securing Kong Gateway"
        "Administering Kong Gateway with decK"
        "Kong Gateway Plugins"
        "Securing Services on Kong"
        "The OpenID Connect (OIDC) Kong plugin"
        "Kong Gateway Observability"
        "Troubleshooting"
        "Reset Virtual Machine"
        "Quit"
    )
COLUMNS=12
select opt in "${lessons[@]}"
do
    case $opt in
        "Kong Gateway Installation")
            export SOURCE_COURSE_ID="KGLL-202"
            config_lab $SOURCE_COURSE_ID
            cd /home/ubuntu/$KONG_COURSE_ID
            exit 0
            ;;
        "Upgrading Kong Gateway")
            export SOURCE_COURSE_ID="KGLL-203"
            config_lab $SOURCE_COURSE_ID
            cd /home/ubuntu/$KONG_COURSE_ID
            exit 0
            ;;
        "Securing Kong Gateway")
            export SOURCE_COURSE_ID="KGLL-204"
            config_lab $SOURCE_COURSE_ID
            cd /home/ubuntu/$KONG_COURSE_ID
            exit 0
            ;;
        "Administering Kong Gateway with decK")
            export SOURCE_COURSE_ID="KDLL-202"
            config_lab $SOURCE_COURSE_ID
            cd /home/ubuntu/$KONG_COURSE_ID
            exit 0
            ;;
        "Kong Gateway Plugins")
            export SOURCE_COURSE_ID="KGLL-210"
            config_lab $SOURCE_COURSE_ID
            cp -f /home/ubuntu/ca_config/* /home/ubuntu/$KONG_COURSE_ID
            cd /home/ubuntu/$KONG_COURSE_ID
            exit 0
            ;;
        "Securing Services on Kong")
            export SOURCE_COURSE_ID="KGLL-205"
            config_lab $SOURCE_COURSE_ID
            cd /home/ubuntu/$KONG_COURSE_ID
            exit 0
            ;;
        "The OpenID Connect (OIDC) Kong plugin")
            export SOURCE_COURSE_ID="KGLL-206"
            config_lab $SOURCE_COURSE_ID
            cd /home/ubuntu/$KONG_COURSE_ID
            exit 0
            ;;
        "Kong Gateway Observability")
            export SOURCE_COURSE_ID=$(sub_menu)
            # echo $SOURCE_COURSE_ID Yay!
            # export SOURCE_COURSE_ID
            config_lab $SOURCE_COURSE_ID
            cd /home/ubuntu/$KONG_COURSE_ID
            # exit 0
            ;;
        "Troubleshooting")
            export SOURCE_COURSE_ID="KGLL-209"
            config_lab $SOURCE_COURSE_ID
            cd /home/ubuntu/$KONG_COURSE_ID
            exit 0
            ;;
        "Reset Virtual Machine")
            sleep 1
            printf "\n${green}Resetting the environment.\n${normal}"
            . /home/ubuntu/.menu/.reset_lab.sh
            export CURRENT_LAB=$opt
            exit 0
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

printf "\n${blue}VM configured. Navigate to '$COURSEDIR' to proceed .\n${normal}"
