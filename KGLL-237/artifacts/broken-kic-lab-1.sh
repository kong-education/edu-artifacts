#!/bin/bash

kubectl -n kong delete -f /home/ubuntu/$KONG_COURSE_ID/httpbin-service.yaml

kubectl -n kong apply -f /home/ubuntu/$KONG_COURSE_ID/troubleshooting/broken-kic-lab-1.yaml


# http -h get $KONG_PROXY_URL/anything