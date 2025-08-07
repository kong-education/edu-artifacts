#!/bin/bash

source ~/.envs
blk=$(tput -T screen setaf 0)
red=$(tput -T screen setaf 1)
grn=$(tput -T screen setaf 2)
ylw=$(tput -T screen setaf 3)
blu=$(tput -T screen setaf 4)
mag=$(tput -T screen setaf 5)
cyn=$(tput -T screen setaf 6)
wit=$(tput -T screen setaf 7)
nrm=$(tput -T screen sgr0)

curl -sL https://download.konghq.com/kong-mesh-binaries-release/kong-mesh-$KONG_MESH_VERSION-linux-amd64.tar.gz | tar --strip-components 2 -xz -C /tmp kong-mesh-$KONG_MESH_VERSION/bin/kumactl
cp /tmp/kumactl /usr/local/bin/
rm -fr /tmp/kumactl

printf "\n\n${grn}Generating Config for kumactl to access GCP${nrm}\n\n"
# Waiting for GCP to become available
while ! httping -lqc1 https://$STRIGO_RESOURCE_0_DNS:30003 ; do sleep 1 ; done
ADMIN_USER_TOKEN=$(ssh $STRIGO_RESOURCE_0_DNS "kubectl -n kong-mesh-system get secret admin-user-token --template={{.data.value}} | base64 -d")
kumactl config control-planes add \
  --name my-control-plane \
  --address https://$STRIGO_RESOURCE_0_DNS:30003 \
  --auth-type=tokens \
  --auth-conf token=$ADMIN_USER_TOKEN \
  --overwrite