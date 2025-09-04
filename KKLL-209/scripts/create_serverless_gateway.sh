#!/bin/bash
KONG_COURSE_ID=KKLL-209

export BLUE='\033[34m'
export GREEN='\033[32m'
export RED='\033[0;31m'
export YELLOW='\033[0;33m'
export AMBER='\033[38;5;214m'
export NC='\033[0m' # No Color


if [ -z "$PAT" ]; then
    echo "Enter your Personal Access Token (PAT): "
    read PAT
fi

if [ -z "$GEO" ]; then
    echo "Enter Region you want to use or hit <enter> for "us". Supported regions are us, eu, in, me, au: "
    read GEO
    if [ -z "$GEO" ]; then
        # Set a default value if the user just pressed Enter
        GEO="us"
    fi
fi

# Validate the provided region
case "$GEO" in
  us|eu|in|me|au)
    echo "Processing for region: $GEO"
    ;;
  *)
    echo "Error: Invalid region provided. Supported regions are us, eu, in, me, au."
    exit 1
    ;;
esac

#curl -v -H "Authorization: Bearer $PAT" "https://$GEO.api.konghq.com/v2/control-planes"

HTTP_STATUS=$(curl -sS -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $PAT" "https://$GEO.api.konghq.com/v2/control-planes")

# Validate if PAT is valid status code is not 200.
if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "Error: Invalid PAT or API request failed. Received HTTP status code: $HTTP_STATUS" >&2
    exit 1
fi

export GEO
export PAT
export KONG_COURSE_ID="KKLL-209"
export GATEWAY_NAME="serverless-$KONG_COURSE_ID"
export GATEWAY_DESCRIPTION="This is the control plane for course $KONG_COURSE_ID"
export DECK_GATEWAY_NAME=$GATEWAY_NAME # Req'd for deck

# Create the control plane
printf "${BLUE}Creating the control plane '$GATEWAY_NAME'...${NC}\n"
curl -s -o /dev/null --request POST \
  --url https://$GEO.api.konghq.com/v2/control-planes \
  --header 'Accept: application/json, application/problem+json' \
  --header "Authorization: Bearer $PAT" \
  --header 'Content-Type: application/json' \
  --data '{
  "name": "'"$GATEWAY_NAME"'",
  "description": "'"$GATEWAY_DESCRIPTION"'",
  "cluster_type": "CLUSTER_TYPE_SERVERLESS",
  "cloud_gateway": false,
  "labels": {"course": "'"$KONG_COURSE_ID"'"}
  }'

sleep 3

export CONTROL_PLANE_ID=$(curl -s -X GET https://"$GEO".api.konghq.com/v2/control-planes -H "Authorization: Bearer $PAT" | jq -r --arg gw "$GATEWAY_NAME" '.data[] | select(.name == $gw) | .id')

# Create the data plane
printf "${BLUE}Creating the data plane...${NC}\n"

curl -s -o /dev/null -X PUT "https://global.api.konghq.com/v3/cloud-gateways/configurations" \
    -H "Accept: application/json"\
    -H "Content-Type: application/json"\
    -H "Authorization: Bearer $PAT" \
    --data '{
      "control_plane_id":  "'"$CONTROL_PLANE_ID"'",
      "control_plane_geo": "'"$GEO"'",
      "dataplane_groups": [
        {
          "region": "na"
        }
      ],
      "kind": "serverless.v0"
    }'


while true; do
  STATE=$(curl -s -X GET "https://global.api.konghq.com/v3/cloud-gateways/configurations" \
    -H "Authorization: Bearer $PAT" \
    -H "Content-Type: application/json" \
    | jq -r --arg CP_ID "$CONTROL_PLANE_ID" '.data[] | select(.control_plane_id == $CP_ID) | .dataplane_groups[].state')

  if [[ "$STATE" == "ready" ]]; then
    printf "${GREEN}Proxy is ready${NC}\n"
    break
  elif [[ "$STATE" == "null" || -z "$STATE" ]]; then
    printf "${AMBER}Proxy is still initializing...${NC}\n"
  else
    printf "${AMBER}Initializing...${NC}\n"
  fi

  sleep 5 
done

# Fetch proxy_url
PROXY_URL=$(curl -s -X GET "https://global.api.konghq.com/v3/cloud-gateways/configurations" \
  -H "Authorization: Bearer $PAT" \
  | jq -r --arg CP_ID "$CONTROL_PLANE_ID" '.data[] | select(.control_plane_id == $CP_ID) | .dataplane_groups[].hostnames[]')


cat <<EOF > $HOME/.envs$KONG_COURSE_ID
export PROXY_URL="$PROXY_URL"
export GEO="$GEO"
export $PAT="$PAT"
export DECK_GATEWAY_NAME=$DECK_GATEWAY_NAME
EOF
source $HOME/.envs$KONG_COURSE_ID

cat <<EOF> $HOME/.deck.yaml 
konnect-addr: https://$GEO.api.konghq.com
konnect-token: $PAT
konnect-control-plane-name: $GATEWAY_NAME
EOF

printf "System is ready. Your Proxy URL is: ${BLUE}https://$PROXY_URL${NC}\n\n"
