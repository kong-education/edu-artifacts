#!/usr/bin/env bash
CURRENTDIR=`pwd`

source ~/.envs

cd /home/labuser/$KONG_COURSE_ID/

yq -i '.env.admin_gui_url = env(KONG_MANAGER_URL)' ./exercises/troubleshooting/cp-values-debug.yaml
yq -i '.env.admin_api_url = env(KONG_ADMIN_API_URL)' ./exercises/troubleshooting/cp-values-debug.yaml
yq -i '.env.admin_api_uri = env(KONG_ADMIN_API_URI)' ./exercises/troubleshooting/cp-values-debug.yaml
yq -i '.env.proxy_url = env(KONG_PROXY_URL)' ./exercises/troubleshooting/cp-values-debug.yaml
yq -i '.env.portal_api_url = env(KONG_PORTAL_API_URL)' ./exercises/troubleshooting/cp-values-debug.yaml
yq -i '.env.portal_gui_host = env(KONG_PORTAL_GUI_HOST)' ./exercises/troubleshooting/cp-values-debug.yaml

helm upgrade -f ./exercises/troubleshooting/cp-values-debug.yaml kong kong/kong -n kong \
--set manager.ingress.hostname=$KONG_MANAGER_URI \
--set portal.ingress.hostname=$KONG_PORTAL_GUI_HOST \
--set admin.ingress.hostname=$KONG_ADMIN_API_URI \
--set portalapi.ingress.hostname=$KONG_PORTAL_API_URI 

cd $CURRENTDIR