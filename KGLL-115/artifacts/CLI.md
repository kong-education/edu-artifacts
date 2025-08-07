# CLI

```shell
pwd
PAT=<Paste the copied value here>

cat <<EOF> ~/.deck.yaml 
konnect-addr: https://us.api.konghq.com
konnect-token: $PAT
konnect-control-plane-name: "flights-team"
EOF

deck gateway ping

cat << EOF | deck gateway apply -
_format_version: "3.0"
_konnect:
  control_plane_name: flights-team
certificates:
  - id: "$(uuidgen)"
    cert: |
$(cat /etc/kong/ssl/server.crt | sed 's/^/      /')
    key: |
$(cat /etc/kong/ssl/server.key | sed 's/^/      /')
    snis:
    - name: "$FQDN"
EOF

yq eval '.networks."kong-edu-net".external = true' -i KongAir/docker-compose.yaml
docker compose -f KongAir/docker-compose.yaml up -d
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
yq KongAir/docker-compose.yaml
https GET https://$KONNECT_GATEWAY/flights
https https://$KONNECT_GATEWAY/health

cat << EOF | deck gateway apply -
_format_version: "3.0"
_konnect:
  control_plane_name: flights-team
plugins:
- config:
    credentials: true
    exposed_headers:
    - X-Auth-Token
    - apiKey
    - x-consumer-username
    headers:
    - Accept
    - Accept-Version
    - Content-Length
    - Authorization
    - apiKey
    - Content-MD5
    - Content-Type
    - Date
    - X-Auth-Token
    - x-consumer-username
    max_age: 3600
    methods:
    - GET
    - HEAD
    - PUT
    - PATCH
    - POST
    - DELETE
    - OPTIONS
    - TRACE
    - CONNECT
    origins:
    - '*'
    preflight_continue: false
    private_network: false
  enabled: true
  instance_name: All
  name: cors
  protocols:
  - grpc
  - grpcs
  - http
  - https
EOF
```
