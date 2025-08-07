#!/bin/bash

# Note: This script is only to be used if the learner quickly wants to change their token

# Usage: update_pat.sh <new_pat>

NEW_PAT=$1

# Update ~/.deck.yaml
yq eval ".konnect-token = \"$NEW_PAT\"" -i ~/.deck.yaml

# Update ~/.lab_vars
sed -i "s/^export MYPAT=.*/export MYPAT=$NEW_PAT/" ~/.lab_vars

echo "$NEW_PAT" > ~/.pat

source ~/.lab_vars