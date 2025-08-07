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
    printf "\n\n${red}This host is not UniversalZome!${nrm}\n\n"
    ;;
  K8sZone)
    printf "\n\n${red}This host is not UniversalZome!${nrm}\n\n"
    ;;
  UniversalZone)
    printf "\n\n${red}Deploying the Builtin Gateway on Universal Zone${nrm}\n\n"
    printf "\n\n${grn}Generating a DP token for the Gateway${nrm}\n\n"
    kumactl generate dataplane-token --name edge-gateway --valid-for 360h > /etc/kong/kuma-gateway.token
    printf "\n\n${blu}Generating config for the Builtin Gateway${nrm}\n\n"
    STRIGO_RESOURCE_2_LOCAL_IP=$(ec2metadata --local-ipv4)
    cat > /etc/kong/kuma-gateway.yaml << EOF
    type: Dataplane
    mesh: default
    name: edge-gateway
    networking:
      address: $STRIGO_RESOURCE_2_LOCAL_IP
      gateway:
        type: BUILTIN
        tags:
          kuma.io/service: edge-gateway
      admin:
        port: 9906
EOF
    printf "\n\n${grn}Creating and starting a service for the builtin gateway${nrm}\n\n"
    cat > kuma-gateway.service << EOF
    [Unit]
    Description = Kuma Builtin Gateway
    After = network.target
    
    [Service]
    WorkingDirectory=/etc/kong/
    User=kuma-dp
    ExecStart = /usr/local/bin/kuma-dp --log-output-path=/var/log/kong/kuma-gateway.log run --cp-address=https://localhost:5678 --dataplane-token-file=kuma-gateway.token --dataplane-file=kuma-gateway.yaml --binary-path /usr/local/bin/envoy --ca-cert-file=ssl/ca.crt --dns-enabled=true --opa-enabled=false > /var/kong/log/kuma-gateway.stdout 2> /var/log/kong/kuma-gateway.stderr
    Restart=always
    RestartSec=12
    
    [Install]
    WantedBy = multi-user.target
EOF
    cp kuma-gateway.service /etc/systemd/system
    sudo systemctl enable kuma-gateway.service
    sudo systemctl start kuma-gateway.service
    sudo systemctl status kuma-gateway.service --no-pager

    printf "\n\n${grn}Creating the MeshGateway Object${nrm}\n\n"
    ssh $STRIGO_RESOURCE_0_DNS '
    kubectl apply -f - << EOF
    apiVersion: kuma.io/v1alpha1
    kind: MeshGateway
    mesh: default
    metadata:
      name: edge-gateway
    spec:
      selectors:
      - match:
          kuma.io/service: edge-gateway
      conf:
        listeners:
        - port: 8080
          protocol: HTTP
          tags:
            port: http/8080
EOF'
    
    printf "\n\n${grn}Creating the MeshGatewayRoute Object${nrm}\n\n"
    ssh $STRIGO_RESOURCE_0_DNS '
    kubectl apply -f - << EOF
    apiVersion: kuma.io/v1alpha1
    kind: MeshGatewayRoute
    mesh: default
    metadata:
      name: edge-gateway-route
    spec:
      selectors:
      - match:
          kuma.io/service: edge-gateway
          port: http/8080
      conf:
        http:
          rules:
          - matches:
            - path:
                match: PREFIX
                value: /
            backends:
            - destination:
                kuma.io/service: frontend_kong-mesh-demo_svc_8088
EOF'
    printf "\n\n${grn}Waiting for the endpoint to become available${nrm}\n\n"
    while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' $KONG_MESH_GATEWAY)" != "200" ]]; do sleep 5; done
    printf "\n\n${grn}Testing External Access to the Application${nrm}\n\n"
    printf "\n\n${mag}\$ curl -sIX GET \$KONG_MESH_GATEWAY${nrm}\n\n"
    curl -sIX GET $KONG_MESH_GATEWAY
    printf "\n\n${blu}Deployed the Builtin Gateway on Universal Zone${nrm}\n\n"
    ;;
  *)
    printf "\n\n${red}This host is not Universal Zone!${nrm}\n\n"
    ;;
esac