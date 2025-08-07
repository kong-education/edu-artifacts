#!/usr/bin/env bash

set -x

# KONGHOST=127.0.0.1
#KONGHOST=kongcluster
KONGHOST=localhost

if ! hash jq &> /dev/null; then
  echo "command jq not found, please install jq to run this script..."
  exit 1
fi

# Using BankOnG serices & routes for Kong for Developers course
SERVICE_NAMES=( "bankong_transactions01" "bankong_transactions02" "bankong_transactions03" "bankong_transactions04" "bankong_transactions05" )
ROUTE_NAMES=( "bankong-list-tranactions01" "bankong-list-tranactions02" "bankong-list-tranactions03" "bankong-list-tranactions04" "bankong-list-tranactions05" )
USER_KEYS=( "1234" "12345" "123456" "1234567" "12345678" )
USERS=( "user1" "user2" "user3" "user4" "user5" )
NUMREQS=10

ACTION=${1:-create}
KONG_ADMIN_API=${2:-http://$KONGHOST:8001}
KONG_PROXY=${3:-http://$KONGHOST:8000}
# KONG_PROXY_ALT=${3:-http://$KONGHOST:8010}
KONG_PROXY_ALT=${3:-http://$KONGHOST:8000}
TOKEN=${4:-password}
SPLUNK_HOST=${5:-splunk}
SPLUNK_PORT=${6:-514}

# SERVICE_HOST="httpbin.docker.local"
SERVICE_HOST="mockbin.local"
SERVICE_PORT=8080

function create_global_plugins {
  curl -s -X POST ${KONG_ADMIN_API}/plugins \
    --data "name=tcp-log" \
    --data "config.host=${SPLUNK_HOST}" \
    --data "config.port=${SPLUNK_PORT}" \
    -H "Kong-Admin-Token:${TOKEN}" | jq
}

function create_consumers() {
  INDEX=$1
  CONSUMER="${USERS[$INDEX]}"
  USER_KEY="${USER_KEYS[$INDEX]}"

  curl -k -s -X POST \
  ${KONG_ADMIN_API}/consumers/ \
  --data "username=${CONSUMER}" -H "Kong-Admin-Token:${TOKEN}" | jq

  curl -k -s -X POST \
  --url ${KONG_ADMIN_API}/consumers/${CONSUMER}/key-auth/ \
  --data "key=${USER_KEY}" -H "Kong-Admin-Token:${TOKEN}" | jq
}

function create_services() {
  INDEX=$1
  SERVICE_NAME="${SERVICE_NAMES[$INDEX]}"
  ROUTE_NAME="${ROUTE_NAMES[$INDEX]}"

# For mockbin.local
  curl -s -X POST ${KONG_ADMIN_API}/services \
    --data "name=${SERVICE_NAME}" \
    --data "url=http://${SERVICE_HOST}:${SERVICE_PORT}/request" \
    -H "Kong-Admin-Token:${TOKEN}" | jq

# For httpbin
    # curl -s -X POST ${KONG_ADMIN_API}/services \
    # --data "name=${SERVICE_NAME}" \
    # --data "url=http://${SERVICE_HOST}/get" \
    # -H "Kong-Admin-Token:${TOKEN}" | jq

  curl -s -X POST ${KONG_ADMIN_API}/services/${SERVICE_NAME}/routes \
    --data "name=${ROUTE_NAME}" \
    --data "paths[]=/${ROUTE_NAME}" -H "Kong-Admin-Token:${TOKEN}" | jq

  curl -s -X POST ${KONG_ADMIN_API}/services/${SERVICE_NAME}/plugins \
    --data "name=key-auth" \
    --data "config.key_names=apikey" -H "Kong-Admin-Token:${TOKEN}" | jq
}

function create_all {
#  create_global_plugins
  for i in {0..4};  do
    create_consumers $i
    create_services $i
  done
}

function run_test() {
  INDEX=$1
  INTERATION=$2

  ROUTE_NAME="${ROUTE_NAMES[$INDEX]}"

  KEY_INDEX=$(( RANDOM % 5 ))
  ERR_INDEX=$(( RANDOM % 10 ))

  API_KEY="${USER_KEYS[$KEY_INDEX]}"
  if (( $ERR_INDEX % 2)); then
    KP=${KONG_PROXY}
  else
    KP=${KONG_PROXY_ALT}
  fi
  if [[ "$ERR_INDEX" == "3" ]]; then
    curl -i -k ${KP}/${ROUTE_NAME}/badroute \
      -H "apikey: ${API_KEY}"
    echo -e "\n"
  elif [[ "$ERR_INDEX" == "7" ]]; then
    curl -i -k ${KP}/${ROUTE_NAME} \
      -H "apikey: ${API_KEY}-badkey"
    echo -e "\n"
  else
    curl -i -k ${KP}/${ROUTE_NAME} \
      -H "apikey: ${API_KEY}"

    echo -e "\n"
  fi
  echo "Iteration: ${INTERATION}"
  sleep 0.3
}

function clean() {

  for i in {0..4}; do

    curl -i -X DELETE -k \
      ${KONG_ADMIN_API}/consumers/${USERS[$i]} \
      -H "Kong-Admin-Token:${TOKEN}"

    KA_ID=$(curl -s ${KONG_ADMIN_API}/${SERVICE_NAMES[$i]}/plugins \
      -H "Kong-Admin-Token:${TOKEN}" | \
      jq -r '.data[] | select(.name | contains("key-auth"))| .id')

    curl -i -X DELETE -k \
      ${KONG_ADMIN_API}/services/${SERVICE_NAMES[$i]}/pugins/${KA_ID} \
      -H "Kong-Admin-Token:${TOKEN}"

    curl -i -X DELETE -k \
      ${KONG_ADMIN_API}/consumers/${USERS[$i]} -H "Kong-Admin-Token:${TOKEN}"

    curl -i -X DELETE -k \
      ${KONG_ADMIN_API}/routes/${ROUTE_NAMES[$i]} \
      -H "Kong-Admin-Token:${TOKEN}"

    curl -i -X DELETE -k \
      ${KONG_ADMIN_API}/services/${SERVICE_NAMES[$i]} \
      -H "Kong-Admin-Token:${TOKEN}"
  done

  TL_ID=$(curl -s ${KONG_ADMIN_API}/plugins \
    -H "Kong-Admin-Token:${TOKEN}" | \
    jq -r '.data[] | select(.name | contains("tcp-log"))| .id')
  echo "delete tcp-log plugin"
  curl -i -X DELETE -k ${KONG_ADMIN_API}/plugins/${TL_ID} \
    -H "Kong-Admin-Token:${TOKEN}"

}

if [ "${ACTION}" == "create" ]; then
  create_all
  elif [ "${ACTION}" == "test" ]; then
  sleep 4
  for i in $(seq 0 $NUMREQS);  do
    index=$(( RANDOM % 5 ))
    run_test $index $i
  done
elif [ "${ACTION}" == "clean" ]; then
  clean  
fi
