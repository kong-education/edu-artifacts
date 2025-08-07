```shell
source ~/start_lab.sh

env | grep -E '(KONG_|FQDN)' | sort

kubectl cluster-info

kubectl get svc -A

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

kubectl api-resources |grep gateway.networking
./deploy-kic.sh

kubectl get pod -n kong

curl -i $KONG_PROXY_URL

kubectl apply -f https://docs.konghq.com/assets/kubernetes-ingress-controller/examples/httpbin-service.yaml -n kong

kubectl get deployment -n kong

echo '
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: kong
  annotations:
    konghq.com/gatewayclass-unmanaged: "true"
spec:
  controllerName: konghq.com/kic-gateway-controller
' | kubectl apply -n kong -f -

kubectl describe gatewayclasses.gateway.networking.k8s.io -n kong| grep Status -A10

echo '
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong
spec:
  gatewayClassName: kong
  listeners:
  - name: proxy
    port: 80
    protocol: HTTP
  - name: proxy-ssl
    port: 443
    protocol: HTTP
' | kubectl apply -n kong -f -

kubectl get gateway kong -n kong -o jsonpath='{.status}' | jq .conditions

echo 'apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
 name: httpbin
spec:
 parentRefs:
 - name: kong
 rules:
 - matches:
   - path:
       type: PathPrefix
       value: /anything
   backendRefs:
   - name: httpbin
     kind: Service
     port: 80
' | kubectl apply -n kong -f -

curl -i $KONG_PROXY_URL/anything

kubectl explain httproute.spec.rules.filters

echo 'apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
 name: httpbin
spec:
 parentRefs:
 - name: kong
 rules:
 - matches:
   - path:
       type: PathPrefix
       value: /anything
   filters: 
     - type: RequestHeaderModifier
       requestHeaderModifier:
         add:
          - name: x-gruber-id
            value: "37"
   backendRefs:
   - name: httpbin
     kind: Service
     port: 80
' | kubectl apply -n kong -f -

curl -i $KONG_PROXY_URL/anything

curl $KONG_ADMIN_GUI_API_URL/plugins -s | jq .data[].config.append

echo 'apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
 name: httpbin
spec:
 parentRefs:
 - name: kong
 rules:
 - matches:
   - path:
       type: PathPrefix
       value: /anything
   filters: 
     - type: RequestHeaderModifier
       requestHeaderModifier:
         add:
          - name: x-gruber-id
            value: "37"
     - type: ResponseHeaderModifier
       responseHeaderModifier:
         add:
          - name: x-mcclane-id
            value: "42"
   backendRefs:
   - name: httpbin
     kind: Service
     port: 80
' | kubectl apply -n kong -f -

curl -i $KONG_PROXY_URL/anything

echo 'apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
 name: httpbin
spec:
 parentRefs:
 - name: kong
 rules:
 - matches:
   - path:
       type: PathPrefix
       value: /anything
   filters: 
     - type: RequestHeaderModifier
       requestHeaderModifier:
         add:
          - name: x-gruber-id
            value: "37"
         remove: ["accept"]
     - type: ResponseHeaderModifier
       responseHeaderModifier:
         add:
          - name: x-mcclane-id
            value: "42"
   backendRefs:
   - name: httpbin
     kind: Service
     port: 80
' | kubectl apply -n kong -f -

curl -i $KONG_PROXY_URL/anything

kubectl create secret generic uid-pw --from-literal=password=kong --from-literal=username=gruber -n kong

kubectl label secret uid-pw konghq.com/credential=basic-auth -n kong

echo '
apiVersion: configuration.konghq.com/v1
kind: KongConsumer
metadata:
  name: gruber
  annotations:
    kubernetes.io/ingress.class: kong
username: gruber
credentials:
- uid-pw
' | kubectl apply -n kong -f -

echo '
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: basic-auth-plugin
config: 
  hide_credentials: true
plugin: basic-auth
' | kubectl apply -n kong -f -

echo 'apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
 name: httpbin
spec:
 parentRefs:
 - name: kong
 rules:
 - matches:
   - path:
       type: PathPrefix
       value: /anything
   filters:
     - type: ExtensionRef
       extensionRef:
         group: configuration.konghq.com
         kind: KongPlugin
         name: basic-auth-plugin
   backendRefs:
   - name: httpbin
     kind: Service
     port: 80
' | kubectl apply -n kong -f -

curl -i $KONG_PROXY_URL/anything

curl --user gruber:kong $KONG_PROXY_URL/anything

echo 'apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: request-termination
config: 
  status_code: 200
  body: "'Yippee ki yay!'"
plugin: request-termination
' | kubectl apply -n kong -f -

echo 'apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
 name: httpbinv2
spec:
 parentRefs:
 - name: kong
 rules:
 - matches:
   - path:
       type: PathPrefix
       value: /stop
   filters:
     - type: ExtensionRef
       extensionRef:
         group: configuration.konghq.com
         kind: KongPlugin
         name: request-termination
   backendRefs:
   - name: httpbin
     kind: Service
     port: 80
' | kubectl apply -n kong -f -

curl -i $KONG_PROXY_URL/stop
```