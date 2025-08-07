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

# Set Konnect API Endpoints

REGION=$1
KAPI="https://$REGION.api.konghq.com"

PAT=$2
# Update the Terraform vars file
TFVARS_FILE="$COURSEDIR/terraform.tfvars"
sed -i "s|^system_account_access_token = \".*\"|system_account_access_token = \"$PAT\"|" "$TFVARS_FILE"
sed -i "s|^server_url = \".*\"|server_url = \"$KAPI\"|" "$TFVARS_FILE"

# Initialise Terraform
printf "\n\n${blu}Initializing Terraform...${nrm}\n\n"
terraform init -input=false > /dev/null 2>&1

# Apply Terraform
printf "\n\n${blu}Applying Terraform...${nrm}\n\n"
terraform apply -input=false -var-file="terraform.tfvars" -auto-approve