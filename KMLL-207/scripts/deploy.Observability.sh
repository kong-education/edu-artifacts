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

kubectl apply -f - << EOF
apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
 name: metrics-default
 namespace: kong-mesh-system
 labels:
   kuma.io/mesh: default
spec:
 targetRef:
   kind: Mesh
 default:
   sidecar:
     includeUnused: true
     profiles:
       appendProfiles:
       - name: Basic
   backends:
   - type: Prometheus
     prometheus:
       port: 5670
       path: /metrics
EOF

kubectl apply -f - << EOF
apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
 name: logging-default
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
       backends:
         - type: File
           file:
             path: /dev/stdout
 to:
   - targetRef:
       kind: Mesh
     default:
       backends:
         - type: File
           file:
             path: /dev/stdout
EOF

kubectl apply -f - << EOF
apiVersion: kuma.io/v1alpha1
kind: MeshTrace
metadata:
  name: default-tracing
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
    - type: Zipkin
      zipkin:
        url: http://jaeger-collector.mesh-observability:9411/api/v2/spans
EOF

kumactl install observability | kubectl apply -f -
kubectl -n mesh-observability wait --for=condition=available --timeout=600s deployment/prometheus-server

kubectl -n mesh-observability patch svc prometheus-server --type=merge --patch-file=/dev/stdin << EOF
{
  "spec": {
    "type": "NodePort",
    "ports": [
      {
        "name": "http",
        "port": 80,
        "targetPort": 9090,
        "nodePort": 30101
      }
    ]
  }
}
EOF

kubectl -n mesh-observability patch svc grafana --type=merge --patch-file=/dev/stdin << EOF
{
  "spec": {
    "type": "NodePort",
    "ports": [
      {
        "name": "http",
        "port": 80,
        "targetPort": 3000,
        "nodePort": 30102
      }
    ]
  }
}
EOF

kubectl -n mesh-observability patch configmap grafana --type=merge --patch-file=/dev/stdin << EOF
data:
  grafana.ini: |
    [analytics]
    check_for_updates = false
    [grafana_net]
    url = https://grafana.net
    [log]
    mode = console
    [paths]
    data = /var/lib/grafana/data
    logs = /var/log/grafana
    plugins = /var/lib/grafana/plugins
    provisioning = /etc/grafana/provisioning
    [plugins]
    allow_loading_unsigned_plugins = "kumahq-kuma-datasource"
    [server]
    root_url = https://${GRAFANA}/
    domain = ${GRAFANA}
    serve_from_sub_path = false
    [auth]
    disable_login_form = true
    [auth.anonymous]
    enabled = true
    org_role = Admin
EOF

kubectl -n mesh-observability rollout restart deployment/grafana
