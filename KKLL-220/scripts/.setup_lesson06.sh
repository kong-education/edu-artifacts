#!/bin/bash

# Konnect Terraform Provider
logger -i -p info -t STRIGO "Running common setup script."

source /home/ubuntu/.envs
source $COURSEDIR/setScriptConfig
rm -f /home/ubuntu/.deck.yaml 
chmod +x $COURSEDIR/create_tf_dp.sh
echo "This script will reset your control plane and replace your data plane. Are you sure you want to continue? (Y/n)"
read response 

if [[ ! $response =~ ^[Yy]$ ]]
then
    echo exiting
    exit 1
fi
echo 

red=$(tput setaf 1)
green=$(tput setaf 2)

# Reset the environment
logger -i -p info -t STRIGO "Resetting the lab environment."
if [ "$(docker ps -q)" ] 
then 
    docker kill $(docker ps -q) > /dev/null 2>&1
    docker rm $(docker ps -a -q) > /dev/null 2>&1
fi
docker network prune -f > /dev/null 2>&1


source $COURSEDIR/setPAT.sh
printf "\n\n${grn}Configuring your training environment....${nrm}\n"

export MYPAT=$(cat $PATFILE)
export DECK_KONNECT_TOKEN=$(cat $PATFILE)

cat << EOF > /home/ubuntu/.deck.yaml 
konnect-addr: $KDOMAIN
konnect-token: $DECK_KONNECT_TOKEN
konnect-control-plane-name: Terraform Control Plane
EOF

# Remove the deployed terraform config if it exists
rm -f $COURSEDIR/terraform/terraform.tfstate $COURSEDIR/terraform/terraform.tfstate.backup > /dev/null 2>&1



echo "export KONNECT_GATEWAY=$STRIGO_RESOURCE_DNS:8000" >> /home/ubuntu/.envs

mkdir -p  /home/ubuntu/.config/httpie
cat <<EOF > /home/ubuntu/.config/httpie/config.json 
{
  "default_options": [
    "--verify=no",
    "--check-status",
    "--auth-type=bearer",
    "--auth=$DECK_KONNECT_TOKEN"
  ]
}
EOF

export MYPAT=$DECK_KONNECT_TOKEN
echo "export MYPAT=$MYPAT" >> /home/ubuntu/.lab_vars

# Remove Terraform data plane
KAPI="https://us.api.konghq.com/v2"
CP_NAME="Terraform Control Plane"
CP=$(http GET "$KAPI/control-planes"  | jq --arg CP_NAME "$CP_NAME" '.data[] | select(.name == $CP_NAME)') 
CP_ID=$(echo $CP | jq -r '.id')
if [ "$CP" ] ; then
  logger -i -p info -t STRIGO "$CP_NAME Control Plane already exists. Deleting it."
  https DELETE "$KAPI/control-planes/$CP_ID" > /dev/null 2>&1
fi


cd $COURSEDIR/terraform

source /home/ubuntu/.lab_vars
printf "\n${green}Completed Setting up Lab Environment.
You should remain in the directory '$COURSEDIR/terraform' for this lesson unless instructions direct you otherwise.${normal}

${red}Please run the command 'source /home/ubuntu/.lab_vars' to set your environment variables.${normal}\n"

# This to check in class if/when this script was executed
echo -e "Finished $(date)\n" >> /home/ubuntu/lab_setup.log


