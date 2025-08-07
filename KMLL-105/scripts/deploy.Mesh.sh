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
ENVF="/home/ubuntu/.envs"
source $ENVF

KONG_MESH_VERSION="2.7.10"

# change to $HOME folder
cd /home/ubuntu/$KONG_COURSE_ID

printf "\n\n${ylw}Removing Existing KinD Cluster${nrm}\n\n"
existingCluster=$(kind get clusters)
if [[ $existingCluster == "k8sg" ]]; then kind delete cluster --name k8sg; fi
rm -fr ~/.kube ~/.kumactl ~/.cache/helm ~/.config/helm /etc/kong/kuma*.* /etc/kong/values*.* > /dev/null 2>&1
   
printf "\n\n${grn}Downloading Kong Mesh Binaries${nrm}\n\n"
curl -sLX GET https://docs.konghq.com/mesh/installer.sh | VERSION=$KONG_MESH_VERSION sh -
cp -v ./kong-mesh-$KONG_MESH_VERSION/bin/* /usr/local/bin/
    
# Create the K8s cluster
printf "\n\n${grn}Creating k8sg Cluster${nrm}\n\n"
kind create cluster --name k8sg --config=KinD.yaml
    
printf "\n\n${grn}Setting up the namespace and Related Assets${nrm}\n\n"
kubectl create ns kong-mesh-system
kubectl -n kong-mesh-system create secret generic kong-mesh-license \
  --from-file=/etc/kong/license.json
    
printf "\n\n${grn}Creating the Mesh helm Values File${nrm}\n\n"
    
    cat > /etc/kong/values.K8sZone.yaml << EOF
    kuma:
      nameOverride: kong-mesh
      # The default registry and tag to use for all Kuma images
      global:
        image:
          registry: "docker.io/kong"
          tag: "$KONG_MESH_VERSION"
    
      controlPlane:
        image:
          repository: "kuma-cp"
          pullPolicy: IfNotPresent          
    
        # -- Kuma CP log level: one of off,info,debug
        logLevel: "info"
    
        # -- Kuma CP modes: one of standalone,zone,global
        mode: "standalone"
    
        autoScaling:
          enabled: false
          minReplicas: 1
          maxReplicas: 2
    
        injectorFailurePolicy: "Ignore"
    
        service:
          # -- Service type of the Kuma Control Plane
          type: NodePort
          apiServer:
            http:
              nodePort: 30002
            https:
              nodePort: 30003
        
        defaults:
          # -- Whether or not to skip creating the default Mesh
          skipMeshCreation: false
    
        secrets:
        - Env: "KMESH_LICENSE_INLINE"
          Secret: "kong-mesh-license"
          Key: "license.json"        
    
        webhooks:
          validator:
            additionalRules: |
              - apiGroups:
                  - kuma.io
                apiVersions:
                  - v1alpha1
                operations:
                  - CREATE
                  - UPDATE
                  - DELETE
                resources:
                  - opapolicies
          ownerReference:
            additionalRules: |
              - apiGroups:
                  - kuma.io
                apiVersions:
                  - v1alpha1
                operations:
                  - CREATE
                resources:
                  - opapolicies
      # Configuration for the kuma dataplane sidecar
      dataPlane:
        image:
          repository: "kuma-dp"
    
        # Configuration for the kuma init phase in the sidecar
        initImage:
          repository: "kuma-init"
EOF

    printf "\n\n${grn}Adding helm Repo and Deploying Mesh Using Values File${nrm}\n\n"
    helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
    helm repo update
    helm -n kong-mesh-system install kong-mesh kong-mesh/kong-mesh \
        --version "$KONG_MESH_VERSION" -f /etc/kong/values.K8sZone.yaml
    CP_POD=$(kubectl -n kong-mesh-system get pods --selector=app=kong-mesh-control-plane -o jsonpath='{.items[*].metadata.name}')
    kubectl -n kong-mesh-system wait --for=condition=Ready --timeout=300s pod $CP_POD
    while ! httping -lqc1 https://$STRIGO_RESOURCE_0_DNS:30003 ; do sleep 1 ; done
    printf "\n\n${grn}Generating Config for kumactl to access CP${nrm}\n\n"
    kumactl config control-planes add \
        --name my-control-plane \
        --address https://$STRIGO_RESOURCE_0_DNS:30003 \
        --overwrite

    kubectl -n kong-mesh-system wait --for=condition=ready pod -l app=kong-mesh-control-plane --timeout=24s
    timeout=42
    end=$((SECONDS+timeout))
    while true; do
      meshExists=$(kubectl get mesh "default" --ignore-not-found)
      if [[ ! -z "$meshExists" ]]; then
        break
      elif [[ $SECONDS -ge $end ]]; then
        printf "\n\n${red}Timeout reached. Mesh 'default' is not available${nrm}\n\n"
        exit 1
      else
        sleep 6
      fi
    done

    printf "\n\n${grn}Adding Default MeshTrafficPermission policy${nrm}\n\n"
    kubectl apply -f - << EOF
    apiVersion: kuma.io/v1alpha1
    kind: MeshTrafficPermission
    metadata:
      name: mesh-traffic-permission-all-default
      namespace: kong-mesh-system
      labels:
        kuma.io/mesh: default
    spec:
      targetRef:
        kind: Mesh
      from:
      - targetRef:
          kind: Mesh
        default:
          action: Allow
EOF

    printf "\n\n${grn}Enabling mTLS and Zone Egress${nrm}\n\n"
    kubectl -n kong-mesh-system patch mesh default --type=merge --patch-file=/dev/stdin << EOF
    apiVersion: kuma.io/v1alpha1
    kind: Mesh
    metadata:
      name: default
    spec:
      networking:
        outbound:
          passthrough: true
      mtls:
        enabledBackend: ca-1
        backends:
        - name: ca-1
          type: builtin
          mode: PERMISSIVE
EOF
