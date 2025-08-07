#!/bin/bash

# Konnect Observability

source /home/ubuntu/.envs
source $COURSEDIR/setScriptConfig

echo "This script will reset your control plane and replace your data plane Kubernetes cluster (if there is one). Are you sure you want to continue? (Y/n)"
read response 

if [[ ! $response =~ ^[Yy]$ ]]
then
    echo exiting
    exit 1
fi
echo 

red=$(tput setaf 1)
green=$(tput setaf 2)
blue=$(tput setaf 4)
normal=$(tput sgr0)

# Reset the environment
if [ "$(docker ps -q)" ] 
then 
    docker kill $(docker ps -q) > /dev/null 2>&1
    docker rm $(docker ps -a -q) > /dev/null 2>&1
fi
docker network prune -f > /dev/null 2>&1
# rm -rf $COURSEDIR/* $COURSEDIR/.* > /dev/null 2>&1


source $COURSEDIR/setPAT.sh

export DECK_KONNECT_TOKEN=$(cat $PATFILE)
cat << EOF > /home/ubuntu/.deck.yaml 
konnect-addr: $KDOMAIN
konnect-token: $DECK_KONNECT_TOKEN
konnect-runtime-group-name: $CP_NAME
EOF

yes | deck reset  > /dev/null 2>&1

# Install Bankong
docker compose -f $COURSEDIR/docker-compose-bankong.yaml up -d  > /dev/null 2>&1

# Install dataplane

"$COURSEDIR"/create_k8s_dataplane.sh

#Install StatsD and Prometheus
kubectl create namespace monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

echo "Installing Monitoring Tools..."
helm install -f $COURSEDIR/artifacts/monitoring/prometheus-values.yaml prometheus prometheus-community/kube-prometheus-stack -n monitoring --wait 
helm install -f $COURSEDIR/artifacts/monitoring/statsd-values.yaml statsd prometheus-community/prometheus-statsd-exporter -n monitoring --wait
helm install -f artifacts/monitoring/grafana-values.yaml grafana grafana/grafana -n monitoring --wait >> /dev/null 2>&1

# rm  ~/.config/httpie/config.json
mkdir -p  ~/.config/httpie
cat <<EOF> ~/.config/httpie/config.json 
{
  "default_options": [
    "--verify=no",
    "--check-status",
    "--auth-type=bearer",
    "--auth=$DECK_KONNECT_TOKEN"
  ]
}
EOF

# source create_k8s_dataplane.sh

cd ~/$KONG_COURSE_ID
# clear

#cp deck/.bankong-base.yaml.ForK8sDP deck/bankong-base.yaml
#deck sync -s deck/bankong-base.yaml
deck sync -s deck/bankong-for-observability.yaml

# This to check in class if/when this script was executed
# touch /home/ubuntu/"Finished_running_$(basename $0)" && $(date) >> $_
echo -e "Finished $(date)\n" >> /home/ubuntu/lab_setup.log

printf "\n${blue}Completed Setting up Lab Environment.

You should remain in the directory '$COURSEDIR' unless instructions direct you otherwise.${normal}\n\n"
