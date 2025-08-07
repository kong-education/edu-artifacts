#!/bin/bash

# Set coulour variables

blk=$(tput -T screen setaf 0)
red=$(tput -T screen setaf 1)
grn=$(tput -T screen setaf 2)
ylw=$(tput -T screen setaf 3)
blu=$(tput -T screen setaf 4)
mag=$(tput -T screen setaf 5)
cyn=$(tput -T screen setaf 6)
wit=$(tput -T screen setaf 7)
nrm=$(tput -T screen sgr0)

# Source ENV variables

COURSEDIR="/home/ubuntu/$KONG_COURSE_ID"
source ~/.envs

# Check if Region and PAT are passed as valid arguments

if [ -z "$1" ] || [ -z "$2" ]; then
  printf "\n\n${blu}Usage: $0 <region> <PAT>${nrm}\n\n"
  exit 1
fi

if [[ "$1" != "us" && "$1" != "eu" && "$1" != "au" ]]; then
  printf "\n\n${red}Error: Invalid region. Allowed values are 'us', 'eu', or 'au'.${nrm}\n\n"
  exit 1
fi

REGION=$1
PAT=$2

# Set Konnect API Endpoints

KAPI="https://$REGION.api.konghq.com/v2"
KIDM="https://global.api.konghq.com/v3"

# Validate PAT

VALIDATED=$(https --headers GET $KAPI/control-planes \
                --auth-type=bearer \
                --auth=$PAT \
                | head -n 1 \
                | cut -d ' ' -f 2)

if [ $VALIDATED -ne 200 ]; then
  printf "\n\n${red}Error: Invalid PAT. Get a valid PAT from https://cloud.konghq.com/global/account/tokens${nrm}\n\n"
  exit 1
fi

# Create CONFIG for HTTPie

mkdir -p ~/.config/httpie
cat << EOF > ~/.config/httpie/config.json 
{
  "default_options": [
    "--verify=no",
    "--check-status",
    "--auth-type=bearer",
    "--auth=$PAT"
  ],
  "check_for_updates": false
}
EOF

# Create CONFIG for decK

cat << EOF > ~/.deck.yaml 
konnect-addr: https://$REGION.api.konghq.com
konnect-token: $PAT
konnect-control-plane-name: "KongAir_Internal"
EOF

# Update the Terraform vars file
TFVARS_FILE="$COURSEDIR/terraform.tfvars"
sed -i "s|^system_account_access_token = \".*\"|system_account_access_token = \"$PAT\"|" "$TFVARS_FILE"
sed -i "s|^server_url = \".*\"|server_url = \"https://$REGION.api.konghq.com\"|" "$TFVARS_FILE"

# Prompt the user for cleanup confirmation
read -p "Do you want to perform a cleanup? (yes/no): " user_input
if [[ "$user_input" =~ ^[Yy]([Ee][Ss])?$ ]]; then
  printf "\n\n${red}Performing cleanup...${nrm}\n\n"

  # Cleanup Existing Artifacts
  terraform init -input=false > /dev/null 2>&1
  terraform destroy -var-file="terraform.tfvars" -auto-approve > /dev/null 2>&1

  # Find IDs of CPs & CPGs
  KAICPID=$(https GET $KAPI/control-planes | jq -r '.data[] | select(.name == "KongAir_Internal") .id')
  KAECPID=$(https GET $KAPI/control-planes | jq -r '.data[] | select(.name == "KongAir_External") .id')  
  KAGCPID=$(https GET $KAPI/control-planes | jq -r '.data[] | select(.name == "KongAir_Global") .id') 
  KAICPGID=$(https GET $KAPI/control-planes | jq -r '.data[] | select(.name == "KongAir_Internal_CP_Group") .id') 
  KAECPGID=$(https GET $KAPI/control-planes | jq -r '.data[] | select(.name == "KongAir_External_CP_Group") .id')  
  # Delete the global rate limiting plugin
  PLUGIN_ID=$(http GET "$KAPI/control-planes/$KAGCPID/core-entities/plugins" 2>/dev/null | \
    yq '.data[] | select(.name == "rate-limiting-advanced") | .id' 2>/dev/null)

  http DELETE "$KAPI/control-planes/$KAGCPID/core-entities/plugins/$PLUGIN_ID" > /dev/null 2>&1

  # Delete CPGs & CPs & DP

  http DELETE $KAPI/control-planes/$KAICPGID > /dev/null 2>&1
  http DELETE $KAPI/control-planes/$KAECPGID > /dev/null 2>&1
  http DELETE $KAPI/control-planes/$KAICPID > /dev/null 2>&1
  http DELETE $KAPI/control-planes/$KAECPID > /dev/null 2>&1
  http DELETE $KAPI/control-planes/$KAGCPID > /dev/null 2>&1
  helm uninstall my-kong --namespace kong-internal  > /dev/null 2>&1

  # Delete System Accounts

  ACCOUNTS=("sa_kong_air_external_dev" "sa_kong_air_internal_dev" "sa_platform_admin" "sa_platform_viewer")

  for account_name in "${ACCOUNTS[@]}"; do
    ACCOUNT_ID=$(http GET "$KIDM/system-accounts" | \
      yq ".data[] | select(.name == \"$account_name\") | .id")
  
    http DELETE "$KIDM/system-accounts/$ACCOUNT_ID"  > /dev/null 2>&1
  done

  # Delete Teams

  TEAMS=("Kong Air Internal Developers" "Kong Air External Developers" "Kong Air Internal Viewers" "Kong Air External Viewers" "Platform Admins" "Platform Viewers")

  for team_name in "${TEAMS[@]}"; do
    TEAM_IDS=$(http GET "$KIDM/teams" | \
      yq ".data[] | select(.name == \"$team_name\") | .id")
  
    for TEAM_ID in $TEAM_IDS; do
      http DELETE "$KIDM/teams/$TEAM_ID" > /dev/null 2>&1

    done
  done
   
  printf "\n\n${red}Cleanup completed.${nrm}\n\n"
else
  printf "\n\n${grn}Cleanup skipped!${nrm}\n\n"
fi

# Prompt the user for deployment confirmation
read -p "Do you want to perform a platfom deployment? (yes/no): " user_input

# Check the user's input
if [[ "$user_input" =~ ^[Yy]([Ee][Ss])?$ ]]; then
  printf "\n\n${grn}Deploying the platform...${nrm}\n\n"
  # Initialise Terraform
  printf "\n\n${blu}Initializing Terraform...${nrm}\n\n"
  terraform init -input=false

  # Apply Terraform
  printf "\n\n${blu}Applying Terraform...${nrm}\n\n"
  terraform apply -input=false -var-file="terraform.tfvars" -auto-approve
  printf "\n\n${grn}Platform deployment completed.${nrm}\n\n"
else
  printf "\n\n${red}Platform deployment skipped!${nrm}\n\n"
fi
