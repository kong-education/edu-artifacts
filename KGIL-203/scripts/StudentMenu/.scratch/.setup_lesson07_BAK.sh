#!/bin/bash

# Plugins for API Traffic Control on Konnect

source /home/ubuntu/.envs
source $COURSEDIR/setScriptConfig

echo "This script will reset your control plane and replace your data plane Kubernetes cluster (if there is one). Are you sure you want to continue? (Y/n)"
read response 

if [[ ! $response =~ ^[Yy]$ ]]
then
    echo exiting
    exit 1
fi
echo

red=$(tput setaf 1)
green=$(tput setaf 2)
blue=$(tput setaf 4)
normal=$(tput sgr0)

# Reset the environment
if [ "$(docker ps -q)" ] 
then 
    docker kill $(docker ps -q) > /dev/null 2>&1
    docker rm $(docker ps -a -q) > /dev/null 2>&1
fi
docker network prune -f > /dev/null 2>&1
# rm -rf $COURSEDIR/* $COURSEDIR/.* > /dev/null 2>&1


source $COURSEDIR/setPAT.sh

export MYPAT=$(cat $PATFILE)
export DECK_KONNECT_TOKEN=$(cat $PATFILE)

cat << EOF > /home/ubuntu/.deck.yaml 
konnect-addr: $KDOMAIN
konnect-token: $DECK_KONNECT_TOKEN
konnect-control-plane-name: $CP_NAME
EOF


docker compose -f $COURSEDIR/docker-compose-bankong.yaml up -d  > /dev/null 2>&1

# This script will create control plane if it doesnt exist and a data plane
"$COURSEDIR"/create_k8s_dataplane.sh

yes | deck reset  > /dev/null 2>&1
cp deck/.bankong-base.yaml.ForK8sDP deck/bankong-base.yaml
# deck sync -s deck/bankong-base.yaml  > /dev/null 2>&1

# rm  ~/.config/httpie/config.json
mkdir -p  ~/.config/httpie
cat <<EOF> ~/.config/httpie/config.json 
{
  "default_options": [
    "--verify=no",
    "--check-status",
    "--auth-type=bearer",
    "--auth=$DECK_KONNECT_TOKEN"
  ]
}
EOF

docker compose -f $COURSEDIR/docker-compose-keycloak.yaml pull > /dev/null 2>&1 &

echo "export MYPAT='$MYPAT'" >> /home/ubuntu/.lab_vars
export CPID=$(https GET https://us.api.konghq.com/v2/control-planes --auth-type=bearer --auth=$MYPAT | jq -r '.data[] | select(.name == "'$CP_NAME'") | .id')
echo "export CPID='$CPID'" >> /home/ubuntu/.lab_vars
echo "export CPURL='https://us.api.konghq.com/v2/control-planes/$CPID'" >> /home/ubuntu/.lab_vars
source /home/ubuntu/.lab_vars

# source create_k8s_dataplane.sh

# cd ~/$KONG_COURSE_ID
# clear

printf "\n${blue}Completed Setting up Lab Environment.

You should remain in the directory '$COURSEDIR' unless instructions direct you otherwise.${normal}\n\n"



# cat <<EOF> $COURSEDIR/get-consumer-uuids.sh
# #!/bin/bash

# USER1=Ann
# USER2=James
# USER3=Sarah

# printf "\n${blue}Getting UUIDs for users $USER1, $USER2, and $USER3. If you used different names, then you need to update this script.\n"
# 
# for user in $USER1 $USER2 $USER3 
#   do 
#   user_ID=$(http $CPURL/core-entities/consumers | jq -r '.data[] | select(.username == "'$user'") | .id') ;
#   echo "$user UUID is $user_ID"
#   user_KEY=$(http $CPURL/core-entities/consumers/$user_ID/key-auth | jq -r '.data[] | select(.username == "'$user'") | .id') ;
#   echo "$user Key is $user_ID"
  
# done
# EOF
# chmod +x get-consumer-uuids.sh


