#!/bin/bash

source ~/start_lab.sh
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml
./deploy-kic.sh
http $KONG_PROXY_URL
kubectl -n kong apply -f kongair/flights-service.yaml
http $KONG_PROXY_URL/flights
echo 'apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: kong
  annotations:
    konghq.com/gatewayclass-unmanaged: "true"
spec:
  controllerName: konghq.com/kic-gateway-controller
---' >> kongair-service.yaml
echo '
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong-gateway
spec:
  gatewayClassName: kong
  listeners:
  - name: proxy
    port: 80
    protocol: HTTP
  - name: proxy-ssl
    port: 443
    protocol: HTTP
---' >> kongair-service.yaml
echo 'apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
 name: kongair-flights
spec:
 parentRefs:
 - name: kong-gateway
 rules:
 - matches:
   - path:
       type: PathPrefix
       value: /flights
   backendRefs:
   - name: kongair-flights
     kind: Service
     port: 5052
---' >> kongair-service.yaml
kubectl -n kong apply -f kongair-service.yaml
http $KONG_PROXY_URL/flights
