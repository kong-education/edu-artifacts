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

# Initialise env variables
source /home/ubuntu/.envs

# change to $HOME folder
cd /home/ubuntu/$KONG_COURSE_ID

case $STRIGO_RESOURCE_NAME in
  "GlobalCP")
    printf "\n\n${ylw}Removing Existing KinD Cluster${nrm}\n\n"
    existingCluster=$(kind get clusters)
    if [[ $existingCluster == "k8sg" ]]; then kind delete cluster --name k8sg; fi
    rm -fr ~/.kube ~/.kumactl ~/.cache/helm ~/.config/helm /etc/kong/kuma*.* /etc/kong/values*.* > /dev/null 2>&1
    ;;
  "K8sZone")
    printf "\n\n${ylw}Cleaning up the node${nrm}\n\n"
    printf "\n\n${ylw}Removing Existing KinD Cluster${nrm}\n\n"
    existingCluster=$(kind get clusters)
    if [[ $existingCluster == "k8sz" ]]; then kind delete cluster --name k8sz; fi
    rm -fr ~/.kube ~/.kumactl ~/.cache/helm ~/.config/helm /etc/kong/kuma*.* /etc/kong/values*.* > /dev/null 2>&1
    ;;
  "UniversalZone")
    printf "\n\n${ylw}Cleaning up the node${nrm}\n\n"
    sudo systemctl stop kuma-gateway > /dev/null 2>&1
    sudo systemctl disable kuma-gateway > /dev/null 2>&1
    sudo systemctl stop kuma-redis > /dev/null 2>&1
    sudo systemctl disable kuma-redis > /dev/null 2>&1
    sudo systemctl stop kuma-dp > /dev/null 2>&1
    sudo systemctl disable kuma-dp > /dev/null 2>&1
    sudo systemctl stop kuma-egress > /dev/null 2>&1
    sudo systemctl disable kuma-egress > /dev/null 2>&1
    sudo systemctl stop kuma-ingress > /dev/null 2>&1
    sudo systemctl disable kuma-ingress > /dev/null 2>&1
    sudo systemctl stop kuma-cp > /dev/null 2>&1
    sudo systemctl disable kuma-cp > /dev/null 2>&1
    docker compose -f /etc/kong/postgres-compose.yaml down -v  > /dev/null 2>&1
    rm -fr ~/.kube ~/.kumactl ~/.cache/helm ~/.config/helm /etc/kong/kuma*.* /etc/kong/values*.* > /dev/null 2>&1
    ;;
  *)
    printf "\n\n${red}This host is not GlobalCP/K8sZone/UniversalZone!${nrm}\n\n"
    ;;
esac