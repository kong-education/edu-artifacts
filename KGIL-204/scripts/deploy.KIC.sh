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


# Wait for INIT script to complete
while [ ! -f /home/ubuntu/.initcomplete ] ; do sleep 1; done

# Initialise env variables
source /home/ubuntu/.envs

# change to $HOME folder
cd /home/ubuntu/$KONG_COURSE_ID

case $STRIGO_RESOURCE_NAME in
  "GlobalCP")
    printf "\n\n${red}This host is not K8sZone!${nrm}\n\n"
    ;;
  K8sZone)
    printf "\n\n${red}Deploying Kong Ingress Controller on K8s Zone${nrm}\n\n"
    kubectl -n kong-mesh-system wait --for=condition=ready pod -l app=kong-mesh-control-plane --timeout=30s
    kubectl create namespace kic-enterprise
    kubectl label namespace kic-enterprise kuma.io/sidecar-injection=enabled
    kubectl -n kic-enterprise create secret generic kong-enterprise-license --from-file=license=/etc/kong/license.json
    helm repo add kong https://charts.konghq.com
    helm repo update
    helm install kic kong/kong --namespace kic-enterprise -f values.kic.yaml --set ingressController.installCRDs=false
    printf "\n\n${grn}Deploying Ingress Resource${nrm}\n\n"
    kubectl apply -f ingressFrontEnd.yaml
    printf "\n\n${grn}Waiting for the endpoint to become available${nrm}\n\n"
    while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' $KONG_MESH_KIC)" != "200" ]]; do sleep 5; done
    printf "\n\n${grn}Testing External Access to the Application${nrm}\n\n"
    printf "\n\n${mag}\$ curl -sIX GET \$KONG_MESH_KIC${nrm}\n\n"
    curl -sIX GET $KONG_MESH_KIC
    printf "\n\n${blu}Deployed the KIC on K8s Zone${nrm}\n\n"
    ;;
  UniversalZone)
    printf "\n\n${red}This host is not K8sZone!${nrm}\n\n"
    ;;
  *)
    printf "\n\n${red}This host is not K8sZone!${nrm}\n\n"
    ;;
esac