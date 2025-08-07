#!/bin/bash

blk=$(tput -T screen setaf 0)
red=$(tput -T screen setaf 1)
grn=$(tput -T screen setaf 2)
ylw=$(tput -T screen setaf 3)
blu=$(tput -T screen setaf 4)
mag=$(tput -T screen setaf 5)
cyn=$(tput -T screen setaf 6)
wit=$(tput -T screen setaf 7)
nrm=$(tput -T screen sgr0)

ENVF="/home/ubuntu/.envs"
source $ENVF

# change to $HOME folder
cd /home/ubuntu/$KONG_COURSE_ID

case $STRIGO_RESOURCE_NAME in
  "GlobalCP")
    printf "\n\n${red}This host is not K8sZone!${nrm}\n\n"
    ;;
  K8sZone)
    printf "\n\n${red}Deploying the Marketplace Demo App on K8s Zone${nrm}\n\n"
    kubectl -n kong-mesh-system wait --for=condition=ready pod -l app=kong-mesh-control-plane --timeout=30s
    kubectl apply -f meshDemoApp.yaml
    kubectl -n kong-mesh-demo wait --for=condition=ready pod -l app=kong-mesh-demo-frontend --timeout=30s
    printf "\n\n${blu}Deployed the Marketplace Demo App on K8s Zone${nrm}\n\n"
    ;;
  UniversalZone)
    printf "\n\n${red}This host is not K8sZone!${nrm}\n\n"
    ;;
  *)
    printf "\n\n${red}This host is not K8sZone!${nrm}\n\n"
    ;;
esac