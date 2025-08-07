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

KONG_MESH_VERSION="2.7.10"

# change to $HOME folder
cd /home/ubuntu/$KONG_COURSE_ID

case $STRIGO_RESOURCE_NAME in
  "GlobalCP")
    printf "\n\n${red}Setting up the GlobalCP${nrm}\n\n"
    printf "\n\n${ylw}Cleaning up the node${nrm}\n\n"
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
    
    printf "\n\n${grn}Creating the root CA Generation Config${nrm}\n\n"
    cat > ca.cfg << EOF
    serial = 007
    expiration_days = 42
    cn = "kuma-ca"
    ca
EOF

    printf "\n\n${grn}Generating the root CA Keypair${nrm}\n\n"
    # Generate a unique 512 bit seed based on hostname
    SEED=$(echo $STRIGO_RESOURCE_0_DNS | od -A n -t x1 | sed 's/ *//g' | tr -d '\n')
    HASH=$(echo -n $SEED | sha256sum | cut -d ' ' -f 1)
    SEED=${HASH:0:56}
    # Generate a 2048 bit RSA key for the host
    certtool --generate-privkey --outfile ca.pss --key-type=rsa --sec-param=medium --seed=$SEED
    certtool --to-rsa --load-privkey ca.pss --outfile ca.key
    certtool --generate-self-signed --hash=sha256 --load-privkey ca.key --outfile ca.crt --template ca.cfg > /dev/null 2>&1
    export CA_CRT=$(cat ca.crt | base64 -w0 -)
    
    printf "\n\n${grn}Generating the Global CP Private Key${nrm}\n\n"
    openssl genrsa -out globalCP.key 2048

    printf "\n\n${grn}Creating the Global CP CSR Config${nrm}\n\n"
    cat > csr.GlobalCP.conf << EOF
    [ req ]
    default_bits = 2048
    prompt = no
    default_md = sha256
    req_extensions = req_ext
    distinguished_name = dn
    
    [ dn ]
    CN = kuma-global-cp
    
    [ req_ext ]
    subjectAltName = @alt_names
    
    [ alt_names ]
    DNS.1 = localhost 
    DNS.2 = kong-mesh-control-plane.kong-mesh-system.svc
    DNS.3 = kong-mesh-control-plane.kong-mesh-system
    DNS.4 = kong-mesh-control-plane
    DNS.5 = $FQDN
EOF

    printf "\n\n${grn}Generating the CSR for Global CP Keypair${nrm}\n\n"
    openssl req -new -key globalCP.key -out globalCP.csr -config csr.GlobalCP.conf
        
    printf "\n\n${grn}Generating Cert Config for Global CP${nrm}\n\n"
    cat > cert.GlobalCP.conf << EOF
    basicConstraints=CA:FALSE
    subjectAltName = @alt_names
    
    [alt_names]
    DNS.1 = localhost 
    DNS.2 = kong-mesh-control-plane.kong-mesh-system.svc
    DNS.3 = kong-mesh-control-plane.kong-mesh-system
    DNS.4 = kong-mesh-control-plane
    DNS.5 = $FQDN
EOF

    printf "\n\n${grn}Generating the Global CP Cert${nrm}\n\n"
    openssl x509 -req \
      -in globalCP.csr \
      -CA ca.crt -CAkey ca.key \
      -CAcreateserial -out globalCP.crt \
      -days 42 \
      -sha256 -extfile cert.GlobalCP.conf
    
    printf "\n\n${grn}Moving Key/Cert Pairs to /etc/kong/ssl${nrm}\n\n"
    mv -v *.key *.crt /etc/kong/ssl/
    rm -v *.pss *.csr
    
    printf "\n\n${grn}Setting up the namespace and Related Assets${nrm}\n\n"
    kubectl create ns kong-mesh-system
    
    kubectl -n kong-mesh-system create secret generic kong-mesh-license \
        --from-file=/etc/kong/license.json
    
    kubectl -n kong-mesh-system create secret generic tls-secret \
        --from-file=ca.crt=/etc/kong/ssl/ca.crt \
        --from-file=tls.crt=/etc/kong/ssl/globalCP.crt \
        --from-file=tls.key=/etc/kong/ssl/globalCP.key

    kubectl -n kong-mesh-system create secret generic api-server-client-certs \
        --from-file=client1.pem=/etc/kong/ssl/globalCP.crt  

    printf "\n\n${grn}Creating the Global CP helm Values File${nrm}\n\n"
    
    cat > /etc/kong/values.GlobalCP.yaml << EOF
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
        mode: "global"
    
        autoScaling:
          enabled: true
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
    
        # -- URL of Global Kuma CP
        globalZoneSyncService:
          # -- Service type of the Global-zone sync
          type: NodePort
          nodePort: 30001
          # -- Port on which Global Zone Sync Service is exposed
          port: 5685
    
        defaults:
          # -- Whether or not to skip creating the default Mesh
          skipMeshCreation: false
    
        # TLS for various servers
        tls:
          general:
            # -- Secret that contains tls.crt, key.crt and ca.crt for protecting Kuma in-cluster communication
            secretName: "tls-secret"
            # -- Base64 encoded CA certificate (the same as in controlPlane.tls.general.secret#ca.crt)
            caBundle: $CA_CRT
          apiServer:
            # -- Secret that contains tls.crt, key.crt for protecting Kuma API on HTTPS
            secretName: "tls-secret"
            # -- Secret that contains list of .pem certificates that can access admin endpoints of Kuma API on HTTPS
            clientCertsSecretName: "api-server-client-certs"
          kdsGlobalServer:
            # -- Secret that contains tls.crt, key.crt for protecting cross cluster communication
            secretName: "tls-secret"
          kdsZoneClient:
            # -- Secret that contains ca.crt which was used to sign KDS Global server. Used for CP verification
            secretName: "tls-secret"
        
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
        --version "$KONG_MESH_VERSION" -f /etc/kong/values.GlobalCP.yaml

    while ! httping -lqc1 https://$STRIGO_RESOURCE_0_DNS:30003 ; do sleep 1 ; done
    printf "\n\n${grn}Generating Config for kumactl to access GCP${nrm}\n\n"
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
      name: allow-all
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

    printf "\n\n${grn}Enabling mTLS and Zone Egress on Global CP${nrm}\n\n"
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
      routing:
        zoneEgress: true
EOF

    printf "\n\n${blu}All Done on GlobalCP${nrm}\n\n"
    ;;
  K8sZone)
    printf "\n\n${red}Setting up K8s Zone${nrm}\n\n"

    printf "\n\n${ylw}Cleaning up the node${nrm}\n\n"
    printf "\n\n${ylw}Removing Existing KinD Cluster${nrm}\n\n"
    existingCluster=$(kind get clusters)
    if [[ $existingCluster == "k8sz" ]]; then kind delete cluster --name k8sz; fi
    rm -fr ~/.kube ~/.kumactl ~/.cache/helm ~/.config/helm /etc/kong/kuma*.* /etc/kong/values*.* > /dev/null 2>&1
        
    printf "\n\n${grn}Downloading Kong Mesh Binaries${nrm}\n\n"
    curl -sLX GET https://docs.konghq.com/mesh/installer.sh | VERSION=$KONG_MESH_VERSION sh -
    cp -v ./kong-mesh-$KONG_MESH_VERSION/bin/* /usr/local/bin/
    
    printf "\n\n${grn}Creating the k8sz Cluster${nrm}\n\n"
    kind create cluster --name k8sz --config=KinD.yaml
    
    printf "\n\n${grn}Creating the root CA Generation Config${nrm}\n\n"
    cat > ca.cfg << EOF
    serial = 007
    expiration_days = 42
    cn = "kuma-ca"
    ca
EOF

    printf "\n\n${grn}Generating the root CA Keypair${nrm}\n\n"
    # Generate a unique 512 bit seed based on hostname
    SEED=$(echo $STRIGO_RESOURCE_0_DNS | od -A n -t x1 | sed 's/ *//g' | tr -d '\n')
    HASH=$(echo -n $SEED | sha256sum | cut -d ' ' -f 1)
    SEED=${HASH:0:56}
    # Generate a 2048 bit RSA key for the host
    certtool --generate-privkey --outfile ca.pss --key-type=rsa --sec-param=medium --seed=$SEED
    certtool --to-rsa --load-privkey ca.pss --outfile ca.key
    certtool --generate-self-signed --hash=sha256 --load-privkey ca.key --outfile ca.crt --template ca.cfg > /dev/null 2>&1
    export CA_CRT=$(cat ca.crt | base64 -w0 -)

    printf "\n\n${grn}Creating the K8s Zone CP Private Key${nrm}\n\n"
    openssl genrsa -out k8sZCP.key 2048
    
    printf "\n\n${grn}Creating the K8S Zone CP CSR Config${nrm}\n\n"
    cat > csr.K8sZCP.conf << EOF
    [ req ]
    default_bits = 2048
    prompt = no
    default_md = sha256
    req_extensions = req_ext
    distinguished_name = dn
    
    [ dn ]
    CN = local-kuma-cp
    
    [ req_ext ]
    subjectAltName = @alt_names
    
    [ alt_names ]
    DNS.1 = localhost 
    DNS.2 = kong-mesh-control-plane.kong-mesh-system.svc
    DNS.3 = kong-mesh-control-plane.kong-mesh-system
    DNS.4 = kong-mesh-control-plane
    DNS.5 = $FQDN
EOF
    
    printf "\n\n${grn}Generating the CSR for the K8S Zone CP Keypair${nrm}\n\n"
    openssl req -new -key k8sZCP.key -out k8sZCP.csr -config csr.K8sZCP.conf
    
    printf "\n\n${grn}Generating the Cert Config for the K8S Zone CP Keypair${nrm}\n\n"
    cat > cert.K8sZCP.conf << EOF
    basicConstraints=CA:FALSE
    subjectAltName = @alt_names
    
    [alt_names]
    DNS.1 = localhost 
    DNS.2 = kong-mesh-control-plane.kong-mesh-system.svc
    DNS.3 = kong-mesh-control-plane.kong-mesh-system
    DNS.4 = kong-mesh-control-plane
    DNS.5 = $FQDN
EOF

    printf "\n\n${grn}Generating the k8s Zone CP Cert${nrm}\n\n"
    openssl x509 -req \
          -in k8sZCP.csr \
          -CA ca.crt -CAkey ca.key \
          -CAcreateserial -out k8sZCP.crt \
          -days 42 \
          -sha256 -extfile cert.K8sZCP.conf

    printf "\n\n${grn}Moving Key/Cert Pairs to /etc/kong/ssl${nrm}\n\n"
    mv -v *.key *.crt /etc/kong/ssl/
    rm -v *.pss

    printf "\n\n${grn}Setting up namespace and Related Assets${nrm}\n\n"
    kubectl create ns kong-mesh-system
    
    kubectl -n kong-mesh-system create secret generic tls-secret \
        --from-file=ca.crt=/etc/kong/ssl/ca.crt \
        --from-file=tls.crt=/etc/kong/ssl/k8sZCP.crt \
        --from-file=tls.key=/etc/kong/ssl/k8sZCP.key
    
    kubectl -n kong-mesh-system create secret generic kong-mesh-tls-cert \
        --from-file=ca.crt=/etc/kong/ssl/ca.crt
    
    kubectl -n kong-mesh-system create secret generic kong-mesh-license \
        --from-file=/etc/kong/license.json
       
    printf "\n\n${grn}Creating the k8s Zone helm Values File${nrm}\n\n"
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

        # -- Kuma CP log level: one of off,info,debug
        logLevel: "info"

        # -- Kuma CP modes: one of standalone,zone,global
        mode: "zone"

        # -- (string) Kuma CP zone, if running multizone
        zone: k8s-zone

        # -- Only used in zone mode
        kdsGlobalAddress: "grpcs://$STRIGO_RESOURCE_0_DNS:30001"

        autoScaling:
          enabled: false
          minReplicas: 1
          maxReplicas: 2

        injectorFailurePolicy: "Ignore"

        service:
          # -- Service type of the Kuma Control Plane
          type: ClusterIP

        defaults:
          # -- Whether or not to skip creating the default Mesh
          skipMeshCreation: false

        # TLS for various servers
        tls:
          general:
            # -- Secret that contains tls.crt, key.crt and ca.crt for protecting Kuma in-cluster communication
            secretName: "tls-secret"
            # -- Base64 encoded CA certificate (the same as in controlPlane.tls.general.secret#ca.crt)
            caBundle: $CA_CRT
          apiServer:
            # -- Secret that contains tls.crt, key.crt for protecting Kuma API on HTTPS
            secretName: "tls-secret"
            # -- Secret that contains list of .pem certificates that can access admin endpoints of Kuma API on HTTPS
            clientCertsSecretName: ""
          kdsGlobalServer:
            # -- Secret that contains tls.crt, key.crt for protecting cross cluster communication
            secretName: "tls-secret"
          kdsZoneClient:
            # -- Secret that contains ca.crt which was used to sign KDS Global server. Used for CP verification
            secretName: "tls-secret"

        image:
          # -- Kuma CP ImagePullPolicy
          pullPolicy: IfNotPresent
          # -- Kuma CP image repository
          repository: "kuma-cp"

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

      ingress:
        enabled: true
        drainTime: 30s
        replicas: 1
        service:
          type: NodePort
          port: 10001
          nodePort: 30004
        annotations:
           kuma.io/ingress-public-address: $STRIGO_RESOURCE_1_DNS
           kuma.io/ingress-public-port: "30004"
        nodeSelector:
          kubernetes.io/os: linux
          kubernetes.io/arch: amd64

      egress:
        # -- If true, it deploys Egress for cross cluster communication
        enabled: true
        # -- Time for which old listener will still be active as draining
        drainTime: 30s
        # -- Number of replicas of the Egress
        replicas: 1
        service:
          # -- Service type of the Egress
          type: ClusterIP
          # -- (string) Optionally specify IP to be used by cloud provider when configuring load balancer
          port: 10002
          # -- Port on which service is exposed on Node for service of type NodePort
        annotations: { }
        # -- Node Selector for the Egress pods
        nodeSelector:
          kubernetes.io/os: linux
          kubernetes.io/arch: amd64
EOF

    printf "\n\n${grn}Adding helm Repo and Deploying Mesh Using Values File${nrm}\n\n"
    helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
    helm repo update
    helm -n kong-mesh-system install kong-mesh kong-mesh/kong-mesh \
        --version $KONG_MESH_VERSION -f /etc/kong/values.K8sZone.yaml
    
    printf "\n\n${grn}Generating an admin token for kumactl to access GCP${nrm}\n\n"
    ADMIN_USER_TOKEN=$(ssh $STRIGO_RESOURCE_0_DNS "kubectl -n kong-mesh-system get secret admin-user-token --template={{.data.value}} | base64 -d") > /dev/null 2>&1
    
    while ! httping -lqc1 https://$STRIGO_RESOURCE_0_DNS:30003 ; do sleep 1 ; done
    printf "\n\n${grn}Generating Config for kumactl to access GCP${nrm}\n\n"
    kumactl config control-planes add \
      --name my-control-plane \
      --address https://$STRIGO_RESOURCE_0_DNS:30003 \
      --auth-type=tokens \
      --auth-conf token=$ADMIN_USER_TOKEN \
      --ca-cert-file=/etc/kong/ssl/ca.crt \
      --overwrite
    
    printf "\n\n${blu}All Done on K8S Zone!${nrm}\n\n"   
    ;;
  UniversalZone)
    # DPP Port assignmentRefreshInterval
    # 9901 Universal Zone CP
    # 9902 Universal Zone CP Bootstrap Server
    # 9903 Universal Zone DP
    # 9904 Universal Zone Ingress
    # 9905 Universal Zone Egress

    printf "\n\n${red}Setting up the Universal Zone${nrm}\n\n"

    printf "\n\n${grn}Cleaning up the node${nrm}\n\n"
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
    
    printf "\n\n${grn}Downloading Kong Mesh Binaries${nrm}\n\n"    
    curl -sLX GET https://docs.konghq.com/mesh/installer.sh | VERSION=$KONG_MESH_VERSION sh -
    cp -v ./kong-mesh-$KONG_MESH_VERSION/bin/* /usr/local/bin/

    printf "\n\n${grn}Generating the root CA Keypair${nrm}\n\n"
    cat > ca.cfg << EOF
    serial = 007
    expiration_days = 42
    cn = "kuma-ca"
    ca
EOF
    
    printf "\n\n${grn}Generating the root CA Keypair${nrm}\n\n"
    # Generate a unique 512 bit seed based on hostname
    SEED=$(echo $STRIGO_RESOURCE_0_DNS | od -A n -t x1 | sed 's/ *//g' | tr -d '\n')
    HASH=$(echo -n $SEED | sha256sum | cut -d ' ' -f 1)
    SEED=${HASH:0:56}
    # Generate a 2048 bit RSA key for the host
    certtool --generate-privkey --outfile ca.pss --key-type=rsa --sec-param=medium --seed=$SEED
    certtool --to-rsa --load-privkey ca.pss --outfile ca.key
    certtool --generate-self-signed --hash=sha256 --load-privkey ca.key --outfile ca.crt --template ca.cfg > /dev/null 2>&1
    export CA_CRT=$(cat ca.crt | base64 -w0 -)
    
    printf "\n\n${grn}Generating the Universal Zone CP Private Key${nrm}\n\n"
    openssl genrsa -out universalCP.key 2048
    
    printf "\n\n${grn}Creating the Universal Zone CP CSR Config${nrm}\n\n"
    cat > csr.UniversalZCP.conf << EOF
    [ req ]
    default_bits = 2048
    prompt = no
    default_md = sha256
    req_extensions = req_ext
    distinguished_name = dn
    
    [ dn ]
    CN = kuma-universal-cp
    
    [ req_ext ]
    subjectAltName = @alt_names
    
    [ alt_names ]
    DNS.1 = localhost 
    DNS.2 = kong-mesh-control-plane.kong-mesh-system.svc
    DNS.3 = kong-mesh-control-plane.kong-mesh-system
    DNS.4 = kong-mesh-control-plane
    DNS.5 = $STRIGO_RESOURCE_2_DNS
EOF
    
    printf "\n\n${grn}Generating the CSR for Universal Zone Keypair${nrm}\n\n"
    openssl req -new -key universalCP.key -out universalCP.csr -config csr.UniversalZCP.conf
    
    printf "\n\n${grn}Generating Cert Config for Universal Zone CP${nrm}\n\n"
    cat > cert.UniversalZCP.conf << EOF
    basicConstraints=CA:FALSE
    subjectAltName = @alt_names
    
    [alt_names]
    DNS.1 = localhost 
    DNS.2 = kong-mesh-control-plane.kong-mesh-system.svc
    DNS.3 = kong-mesh-control-plane.kong-mesh-system
    DNS.4 = kong-mesh-control-plane
    DNS.5 = $STRIGO_RESOURCE_2_DNS
EOF
    
    printf "\n\n${grn}Generating the Universal Zone CP Cert${nrm}\n\n"
    openssl x509 -req \
          -in universalCP.csr \
          -CA ca.crt -CAkey ca.key \
          -CAcreateserial -out universalCP.crt \
          -days 42 \
          -sha256 -extfile cert.UniversalZCP.conf
          
    printf "\n\n${grn}Moving Key/Cert Pairs to /etc/kong/ssl${nrm}\n\n"
    mv -v *.key *.crt /etc/kong/ssl/
    rm -v *.pss

    printf "\n\n${grn}Creating the compose file for the postgres Store${nrm}\n\n"
    cat > /etc/kong/postgres-compose.yaml << EOF
    services:
      postgres:
        image: postgres:17
        network_mode: "host"
        container_name: postgres
        hostname: postgres
        restart: always
        environment:
          POSTGRES_DB: kuma
          POSTGRES_USER: kuma
          POSTGRES_PASSWORD: kuma
EOF
        
    printf "\n\n${grn}Starting the postgres DB Store${nrm}\n\n"
    docker compose -f /etc/kong/postgres-compose.yaml up -d
    
    printf "\n\n${grn}Creating the Systemd File for the CP${nrm}\n\n"
    cat > kuma-cp.service << EOF
    [Unit]
    Description = Kuma Zone Control Plane
    Requires=docker.service
    After = network.target
    After=docker.service
    
    [Service]
    WorkingDirectory=/etc/kong/
    ExecStart = /usr/local/bin/kuma-cp --log-output-path=/var/log/kong/kuma-cp.log run --license-path=license.json --config-file=values.UniversalZone.yaml  &>> /var/log/kong/kuma-cp.stdout
    Restart=always
    RestartSec=12
    
    [Install]
    WantedBy = multi-user.target
EOF

    printf "\n\n${grn}Creating the Config File for the CP${nrm}\n\n"
    
    cat > /etc/kong/values.UniversalZone.yaml << EOF
    {
       "apiServer":{
          "auth":{
             "allowFromLocalhost":true,
             "clientCertsDir":"/etc/kong/ssl"
          },
          "authn":{
            "type":"tokens"
          },
          "corsAllowedDomains":[
             ".*"
          ],
          "http":{
             "enabled":true,
             "interface":"0.0.0.0",
             "port":5681
          },
          "https":{
             "enabled":true,
             "interface":"0.0.0.0",
             "port":5682,
             "tlsCertFile":"/etc/kong/ssl/universalCP.crt",
             "tlsKeyFile":"/etc/kong/ssl/universalCP.key"
          },
          "readOnly":false
       },
       "bootstrapServer":{
          "apiVersion":"v3",
          "params":{
             "adminAccessLogPath":"/dev/null",
             "adminAddress":"127.0.0.1",
             "adminPort":9902,
             "xdsConnectTimeout":"1s",
             "xdsHost":"",
             "xdsPort":5678
          }
       },
       "defaults":{
          "skipMeshCreation":false
       },
       "diagnostics":{
          "debugEndpoints":false,
          "serverPort":5680
       },
       "dnsServer":{
          "CIDR":"240.0.0.0/4",
          "domain":"mesh",
          "port":5353
       },
       "dpServer":{
          "auth":{
             "type":"dpToken"
          },
          "hds":{
             "checkDefaults":{
                "healthyThreshold":1,
                "interval":"1s",
                "noTrafficInterval":"1s",
                "timeout":"2s",
                "unhealthyThreshold":1
             },
             "enabled":true,
             "interval":"5s",
             "refreshInterval":"10s"
          },
          "port":5678,
          "tlsCertFile":"/etc/kong/ssl/universalCP.crt",
          "tlsKeyFile":"/etc/kong/ssl/universalCP.key"
       },
       "environment":"universal",
       "general":{
          "dnsCacheTTL":"10s",
          "tlsCertFile":"/etc/kong/ssl/universalCP.crt",
          "tlsKeyFile":"/etc/kong/ssl/universalCP.key",
          "workDir":"/etc/kong/.kuma"
       },
       "guiServer":{
          "apiServerUrl":""
       },
       "metrics":{
          "dataplane":{
             "enabled":true,
             "subscriptionLimit":10
          },
          "mesh":{
             "maxResyncTimeout":"20s",
             "minResyncTimeout":"1s"
          },
          "zone":{
             "enabled":true,
             "subscriptionLimit":10
          }
       },
       "mode":"zone",
       "monitoringAssignmentServer":{
          "assignmentRefreshInterval":"1s",
          "grpcPort":5676
       },
       "multizone":{
          "global":{
             "kds":{
                "grpcPort":5685,
                "refreshInterval":"1s",
                "tlsCertFile":"/etc/kong/ssl/universalCP.crt",
                "tlsKeyFile":"/etc/kong/ssl/universalCP.key",
                "zoneInsightFlushInterval":"10s"
             },
             "pollTimeout":"500ms"
          },
          "zone":{
             "globalAddress":"grpcs://$STRIGO_RESOURCE_0_DNS:30001",
             "kds":{
                "refreshInterval":"1s",
                "rootCaFile":"/etc/kong/ssl/ca.crt",
    
             },
             "name":"universal-zone"
          }
       },
       "reports":{
          "enabled":true
       },
       "runtime":{
          "kubernetes":{
             "admissionServer":{
                "address":"",
                "certDir":"",
                "port":5443
             },
             "controlPlaneServiceName":"kuma-control-plane",
             "injector":{
                "builtinDNS":{
                   "port":15053
                },
                "caCertFile":"",
                "cniEnabled":false,
                "exceptions":{
                   "labels":{
                      "openshift.io/build.name":"*",
                      "openshift.io/deployer-pod-for.name":"*"
                   }
                },
                "initContainer":{
                   "image":"kuma/kuma-init:$KONG_MESH_VERSION"
                },
                "sidecarContainer":{
                   "adminPort":9901,
                   "drainTime":"5s",
                   "envVars":{
    
                   },
                   "gid":5678,
                   "image":"kuma/kuma-dp:$KONG_MESH_VERSION",
                   "livenessProbe":{
                      "failureThreshold":12,
                      "initialDelaySeconds":60,
                      "periodSeconds":5,
                      "timeoutSeconds":3
                   },
                   "readinessProbe":{
                      "failureThreshold":12,
                      "initialDelaySeconds":1,
                      "periodSeconds":5,
                      "successThreshold":1,
                      "timeoutSeconds":3
                   },
                   "redirectPortInbound":15006,
                   "redirectPortInboundV6":15010,
                   "redirectPortOutbound":15001,
                   "resources":{
                      "limits":{
                         "cpu":"1000m",
                         "memory":"512Mi"
                      },
                      "requests":{
                         "cpu":"50m",
                         "memory":"64Mi"
                      }
                   },
                   "uid":5678
                },
                "sidecarTraffic":{
                   "excludeInboundPorts":[
    
                   ],
                   "excludeOutboundPorts":[
    
                   ]
                },
                "virtualProbesEnabled":true,
                "virtualProbesPort":9000
             },
             "marshalingCacheExpirationTime":"5m0s"
          },
          "universal":{
             "dataplaneCleanupAge":"0h15m0s",
    	 "drainTime":"5"
          }
       },
       "sdsServer":{
          "dataplaneConfigurationRefreshInterval":"1s"
       },
       "store":{
          "cache":{
             "enabled":true,
             "expirationTime":"1s"
          },
          "kubernetes":{
             "systemNamespace":"kuma-system"
          },
          "postgres":{
             "connectionTimeout":5,
             "dbName":"kuma",
             "host":"localhost",
             "maxOpenConnections":0,
             "maxReconnectInterval":"1m0s",
             "minReconnectInterval":"10s",
             "user":"kuma",
             "password":"kuma",
             "port":5432,
             "tls":{
                "caPath":"",
                "certPath":"",
                "keyPath":"",
                "mode":"disable"
             },
          },
          "type":"postgres",
          "upsert":{
             "conflictRetryBaseBackoff":"100ms",
             "conflictRetryMaxTimes":5
          }
       },
       "xdsServer":{
          "dataplaneConfigurationRefreshInterval":"1s",
          "dataplaneStatusFlushInterval":"10s",
          "nackBackoff":"5s"
       }
    }
EOF
    
    printf "\n\n${grn}Migrating DB Store${nrm}\n\n"
    sleep 8
    kuma-cp migrate up --config-file=/etc/kong/values.UniversalZone.yaml
    
    printf "\n\n${grn}Copying & Starting the CP Systemd Service${nrm}\n\n"
    cp kuma-cp.service /etc/systemd/system
    sudo systemctl enable kuma-cp.service
    sudo systemctl start kuma-cp.service
    sudo systemctl status kuma-cp.service --no-pager
    
    printf "\n\n${grn}Generating an admin token for kumactl to access GCP${nrm}\n\n"
    ADMIN_USER_TOKEN=$(ssh $STRIGO_RESOURCE_0_DNS "kubectl -n kong-mesh-system get secret admin-user-token --template={{.data.value}} | base64 -d") > /dev/null 2>&1
    
    while ! httping -lqc1 https://$STRIGO_RESOURCE_0_DNS:30003 ; do sleep 1 ; done
    printf "\n\n${grn}Generating Config for kumactl to access GCP${nrm}\n\n"
    kumactl config control-planes add \
      --name my-control-plane \
      --address https://$STRIGO_RESOURCE_0_DNS:30003 \
      --auth-type=tokens \
      --auth-conf token=$ADMIN_USER_TOKEN \
      --ca-cert-file=/etc/kong/ssl/ca.crt \
      --overwrite

    STRIGO_RESOURCE_2_LOCAL_IP=$(ec2metadata --local-ipv4)
    STRIGO_RESOURCE_2_PUBLIC_IP=$(ec2metadata --public-ipv4)
    STRIGO_RESOURCE_2_PUBLIC_HOST=$(ec2metadata --public-host)
    STRIGO_RESOURCE_2_LOCAL_HOST=$(ec2metadata --local-host)

    printf "\n\n${grn}Setting up the zone ingress${nrm}\n\n"
    cat > kuma-ingress.service << EOF
    [Unit]
    Description = Kuma Zone Ingress
    After = network.target
    
    [Service]
    User=kuma-dp
    Environment="KUMA_READINESS_PORT=1102"
    Environment="KUMA_APPLICATION_PROBE_PROXY_PORT=0"
    WorkingDirectory=/etc/kong/
    ExecStart = /usr/local/bin/kuma-dp --log-output-path=/var/log/kong/kuma-ingress.log run --cp-address=https://localhost:5678 --dataplane-token-file=kuma-ingress.token --dataplane-file=kuma-ingress.yaml --ca-cert-file=ssl/ca.crt --proxy-type ingress &>> /var/log/kong/kuma-ingress.stdout
    Restart=always
    RestartSec=12

    [Install]
    WantedBy = multi-user.target
EOF
    
    cat > /etc/kong/kuma-ingress.yaml << EOF
    type: ZoneIngress
    name: universal-zone-ingress
    networking:
      address: $STRIGO_RESOURCE_2_LOCAL_IP
      port: 10001
      advertisedAddress: $STRIGO_RESOURCE_2_DNS
      advertisedPort: 10001
      admin:
        port: 9904
EOF

    printf "\n\n${grn}Generating a Zone Ingress Token${nrm}\n\n"
    kumactl generate zone-token --zone universal-zone --valid-for 360h --scope ingress > /etc/kong/kuma-ingress.token
        
    printf "\n\n${grn}Creating & Starting the Ingress Service${nrm}\n\n"
    cp kuma-ingress.service /etc/systemd/system
    sudo systemctl enable kuma-ingress.service
    sudo systemctl start kuma-ingress.service
    sudo systemctl status kuma-ingress.service --no-pager

    printf "\n\n${grn}Setting up the Zone Egress${nrm}\n\n"
    cat > kuma-egress.service << EOF
    [Unit]
    Description = Kuma Zone Egress
    After = network.target
    
    [Service]
    WorkingDirectory=/etc/kong/
    User=kuma-dp
    Environment="KUMA_READINESS_PORT=1103"
    Environment="KUMA_APPLICATION_PROBE_PROXY_PORT=0"
    ExecStart = /usr/local/bin/kuma-dp --log-output-path=/var/log/kong/kuma-egress.log run --cp-address=https://localhost:5678 --dataplane-token-file=kuma-egress.token --dataplane-file=kuma-egress.yaml --ca-cert-file=ssl/ca.crt --proxy-type egress &>> /var/log/kong/kuma-egress.stdout
    Restart=always
    RestartSec=12

    [Install]
    WantedBy = multi-user.target
EOF
    
    cat > /etc/kong/kuma-egress.yaml << EOF
    type: ZoneEgress
    name: universal-zone-egress
    networking:
      address: $STRIGO_RESOURCE_2_LOCAL_IP
      port: 10002
      advertisedAddress: $STRIGO_RESOURCE_2_DNS
      advertisedPort: 10002
      admin:
        port: 9905
EOF

    printf "\n\n${grn}Generating a Zone Egress Token${nrm}\n\n"
    kumactl generate zone-token --zone universal-zone --valid-for 360h --scope egress > /etc/kong/kuma-egress.token 
        
    printf "\n\n${grn}Creating & Starting the Egress Service${nrm}\n\n"
    cp kuma-egress.service /etc/systemd/system
    sudo systemctl enable kuma-egress.service
    sudo systemctl start kuma-egress.service
    sudo systemctl status kuma-egress.service --no-pager

    printf "\n\n${grn}Setting up the workload DP${nrm}\n\n"
    cat > kuma-dp.service << EOF
    [Unit]
    Description = Kuma Data Plane
    After = network.target
    
    [Service]
    User=kuma-dp
    Environment="KUMA_READINESS_PORT=1104"
    Environment="KUMA_APPLICATION_PROBE_PROXY_PORT=0"
    WorkingDirectory=/etc/kong/
    ExecStart = /usr/local/bin/kuma-dp --log-output-path=/var/log/kong/kuma-dp.log run --cp-address=https://localhost:5678 --dataplane-token-file=kuma-redis.token --dataplane-file=kuma-redis.yaml --binary-path /usr/local/bin/envoy --ca-cert-file=ssl/ca.crt --dns-enabled=true --opa-enabled=false &>> /var/log/kong/kuma-dp.stdout
    Restart=always
    RestartSec=12

    [Install]
    WantedBy = multi-user.target
EOF
    
    printf "\n\n${grn}Generating the DP non-transparent Config${nrm}\n\n"
    
    cat > /etc/kong/kuma-redis.yaml << EOF
    type: Dataplane
    mesh: default
    name: redis-service-universal
    networking: 
      address: 127.0.0.1
      inbound:
        - port: 7379
          servicePort: 6379
          serviceAddress: 127.0.0.1
          tags: 
            kuma.io/service: redis-service_default_svc_6379
            kuma.io/protocol: tcp
      admin:
        port: 9903
EOF
    
    printf "\n\n${grn}Setting up the workload Service${nrm}\n\n"
    cat > kuma-redis.service << EOF
    [Unit]
    Description=Redis Container
    Requires=docker.service
    After=docker.service

    [Service]
    WorkingDirectory=/etc/kong/
    ExecStartPre=/usr/bin/docker compose -f redis-compose.yaml down
    ExecStartPre=/usr/bin/docker compose -f redis-compose.yaml rm -f
    ExecStartPre=/usr/bin/docker compose -f redis-compose.yaml pull
    ExecStart=/usr/bin/docker compose -f redis-compose.yaml up
    ExecStop=/usr/bin/docker compose -f redis-compose.yaml down
    Restart=always
    TimeoutStartSec=300

    [Install]
    WantedBy=multi-user.target
EOF

    cat > /etc/kong/redis-compose.yaml << EOF
    version: "3"
    services:
  
      redis:
        image: kvn0218/kuma-redis
        container_name: redis
        hostname: redis
        network_mode: "host"
        restart: always
        volumes:
        - /etc/kong/redis-setup.conf:/usr/local/etc/redis/redis.conf
        command: redis-server /usr/local/etc/redis/redis.conf
EOF

    cat > /etc/kong/redis-setup.conf << EOF
    protected-mode yes
    port 6379
    save ""
    appendonly no
EOF

    printf "\n\n${grn}Generating the DP Token${nrm}\n\n"
    kumactl generate dataplane-token --name redis-service-universal --valid-for 360h > /etc/kong/kuma-redis.token
        
    printf "\n\n${grn}Creating & Starting DP Service${nrm}\n\n"
    cp kuma-dp.service /etc/systemd/system
    sudo systemctl enable kuma-dp.service
    sudo systemctl start kuma-dp.service
    sudo systemctl status kuma-dp.service --no-pager
        
    printf "\n\n${grn}Installing the workload service and starting it${nrm}\n\n"
    cp kuma-redis.service /etc/systemd/system
    sudo systemctl enable kuma-redis.service
    sudo systemctl start kuma-redis.service
    sudo systemctl status kuma-redis.service --no-pager
    printf "\n\n${blu}All Done on the Universal Zone${nrm}\n\n"
    ;;
  *)
    printf "\n\n${red}This host is not GlobalCP/K8sZone/UniversalZone!${nrm}\n\n"
    ;;
esac
