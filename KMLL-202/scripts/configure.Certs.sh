#!/bin/bash

# Console TTY Colors
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
    printf "\n\n${red}Setting up the GlobalCP${nrm}\n\n"
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
    ;;
  K8sZone)
    printf "\n\n${red}Setting up K8s Zone${nrm}\n\n"
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
    ;;
  UniversalZone)
    printf "\n\n${red}Setting up the Universal Zone${nrm}\n\n"
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
    ;;
  *)
    printf "\n\n${red}This host is not GlobalCP/K8sZone/UniversalZone!${nrm}\n\n"
    ;;
esac

printf "\n\n${grn}Moving Key/Cert Pairs to /etc/kong/ssl${nrm}\n\n"
mv -v *.key *.crt /etc/kong/ssl/
rm -v *.pss *.csr


printf "\n\n${blu}All Done Generating Key/Cert Pairs for $STRIGO_RESOURCE_NAME${nrm}\n\n"
