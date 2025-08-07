#!/usr/bin/env bash

source /home/ubuntu/.scvs.lst

export KUBECONFIG=/home/ubuntu/.kube/config

# Delete kind cluster
kind delete cluster --name multiverse

CURRENTDIR=$(pwd)
cd /home/ubuntu/$KONG_COURSE_ID/docker-containers
docker-compose down
cd $CURRENTDIR