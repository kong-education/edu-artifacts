#!/bin/bash

# TTY Colors
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
ENVF="/home/ubuntu/.envs"
source $ENVF

# change to $HOME folder
cd /home/ubuntu/$KONG_COURSE_ID

case $STRIGO_RESOURCE_NAME in
  "GlobalCP")
    printf "\n\n${red}This host is not K8sZone!${nrm}\n\n"
    ;;
  K8sZone)
    # Confirm CP Mesh is ready
    printf "\n\n${red}Deploying Kong Ingress Controller on K8s Zone${nrm}\n\n"
    kubectl -n kong-mesh-system wait --for=condition=ready pod -l app=kong-mesh-control-plane --timeout=300s
    # Install the Gateway API CRDs
    kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml
    kubectl api-resources --api-group=gateway.networking.k8s.io

    # Create Gateway & GatewayClass instance
    kubectl -n kong apply -f - << EOF
    apiVersion: gateway.networking.k8s.io/v1
    kind: GatewayClass
    metadata:
      name: kong
      annotations:
        konghq.com/gatewayclass-unmanaged: "true"
    spec:
      controllerName: konghq.com/kic-gateway-controller
EOF
    kubectl apply -f - << EOF
    apiVersion: gateway.networking.k8s.io/v1
    kind: Gateway
    metadata:
      name: kong
      namespace: kong-mesh-demo
    spec:
      gatewayClassName: kong
      listeners:
      - name: proxy
        port: 80
        protocol: HTTP
      - name: proxy-ssl
        port: 443
        protocol: HTTP
EOF

    # Create namespace and assets
    kubectl create namespace kong
    kubectl label namespace kong kuma.io/sidecar-injection=enabled
    kubectl -n kong create secret generic kong-enterprise-license --from-file=license=/etc/kong/license.json
    kubectl -n kong create secret tls kong-cluster-cert --cert=/etc/kong/ssl/cluster.crt --key=/etc/kong/ssl/cluster.key
    kubectl -n kong create secret tls kong-proxy-tls --cert=/etc/kong/ssl/server.crt --key=/etc/kong/ssl/server.key

    # Create helm values file for KIC
    yq -i '.gateway.env.proxy_url = env(KONG_MESH_KIC)' values.kic.yaml

    # Deploy KIC using helm
    helm repo add kong https://charts.konghq.com
    helm repo update
    helm install -n kong kic kong/ingress -f values.kic.yaml

    # Fix tags on proxy
    kubectl -n kong wait --for=condition=ready pod -l app=kic-gateway --timeout=48s
    DATAPLANE_NAME=$(kubectl -n kong get dataplane --no-headers -o custom-columns=":metadata.name" | grep "^kic-gateway" | head -n 1)

    kubectl -n kong patch dataplane "$DATAPLANE_NAME" --type=merge --patch-file=/dev/stdin << EOF
    apiVersion: kuma.io/v1alpha1
    kind: Dataplane
    metadata:
      name: "$DATAPLANE_NAME"
      annotations:
        k8s.kuma.io/service-name: kic-kong-proxy
        k8s.kuma.io/service-port: "80"
        kuma.io/service: kic-kong-proxy_kong_svc_80
    spec:
      networking:
        gateway:
          tags:
            k8s.kuma.io/service-name: kic-kong-proxy
            k8s.kuma.io/service-port: "80"
            kuma.io/service: kic-kong-proxy_kong_svc_80
EOF

    # Create the HTTPRoute
    kubectl apply -f - << EOF
    apiVersion: gateway.networking.k8s.io/v1
    kind: HTTPRoute
    metadata:
      name: marketplace
      namespace: kong-mesh-demo
    spec:
      parentRefs:
        - name: kong
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          backendRefs:
            - name: frontend
              port: 8088
EOF
    # Test KIC access
    printf "\n\n${grn}Waiting for the endpoint to become available${nrm}\n\n"
    while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' $KONG_MESH_KIC)" != "200" ]]; do sleep 5; done
    printf "\n\n${blu}Deployed the KIC on K8s Zone${nrm}\n\n"
    ;;
  UniversalZone)
    printf "\n\n${red}This host is not K8sZone!${nrm}\n\n"
    ;;
  *)
    printf "\n\n${red}This host is not K8sZone!${nrm}\n\n"
    ;;
esac