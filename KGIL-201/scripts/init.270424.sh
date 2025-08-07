# ami-0f63e6c12e9f18d3a
#!/bin/bash

ENVF="/home/ubuntu/.envs"
LOG="/var/log/strigo.log"
[ -e "$LOG" ] || touch "$LOG"
ISO8601="%Y-%m-%dT%H:%M:%S.%3NZ"
printf "%s INIT starting...\n" "$(date -u +$ISO8601)" >> $LOG

printf "%s Creating /home/ubuntu/initlab.sh...\n" "$(date -u +$ISO8601)" >> $LOG
cat <<EOF > /home/ubuntu/start_lab.sh
#!/bin/bash
if [ ! -f /home/ubuntu/.initcomplete ] ; then
  tput bold; echo -e "\nWaiting for the INIT script to finish..."; tput sgr0
fi

while [ ! -f /home/ubuntu/.initcomplete ] ; do 
  for s in / - \\\ \|; do 
    printf "\r\$s"; sleep .1; 
  done; 
done

echo -e "\nINIT script is done!"
sleep 2


cd /home/ubuntu/$(echo "{{ .STRIGO_CLASS_NAME }}" | cut -d ' ' -f 1 | sed 's/\.//')
EOF

chmod 644 /home/ubuntu/initlab.sh
chown ubuntu:ubuntu /home/ubuntu/initlab.sh

# Writing context variables to a file for persistence
printf "%s Writing context variables to ~/.envs for persistence...\n" "$(date -u +$ISO8601)" >> $LOG
cat <<EOF > $ENVF
export FQDN=$(echo "{{ .STRIGO_RESOURCE_DNS }}" | tr '[:upper:]' '[:lower:]')
export KONG_COURSE_ID=$(echo "{{ .STRIGO_CLASS_NAME }}" | cut -d ' ' -f 1 | sed 's/\.//')
export STRIGO_CLASS_ID="{{ .STRIGO_CLASS_ID }}"
export STRIGO_CLASS_NAME="{{ .STRIGO_CLASS_NAME }}"
export STRIGO_EVENT_HOST_EMAIL="{{ .STRIGO_EVENT_HOST_EMAIL }}"
export STRIGO_EVENT_ID="{{ .STRIGO_EVENT_ID }}"
export STRIGO_EVENT_NAME="{{ .STRIGO_EVENT_NAME }}"
export STRIGO_ORG_ID="{{ .STRIGO_ORG_ID }}"
export STRIGO_ORG_NAME="{{ .STRIGO_ORG_NAME }}"
export STRIGO_PARTNER_ID="{{ .STRIGO_PARTNER_ID }}"
export STRIGO_PARTNER_NAME="{{ .STRIGO_PARTNER_NAME }}"
export STRIGO_USER_EMAIL="{{ .STRIGO_USER_EMAIL }}"
export STRIGO_USER_ID="{{ .STRIGO_USER_ID }}"
export STRIGO_USER_NAME="{{ .STRIGO_USER_NAME }}"
export STRIGO_WORKSPACE_FLAVOR="{{ .STRIGO_WORKSPACE_FLAVOR }}"
export STRIGO_WORKSPACE_ID="{{ .STRIGO_WORKSPACE_ID }}"
export STRIGO_RESOURCE_DNS="{{ .STRIGO_RESOURCE_DNS }}"
export STRIGO_RESOURCE_ID="{{ .STRIGO_RESOURCE_ID }}"
export STRIGO_RESOURCE_NAME="{{ .STRIGO_RESOURCE_NAME }}"
export STRIGO_RESOURCE_0_DNS="{{ .STRIGO_RESOURCE_0_DNS }}"
export STRIGO_RESOURCE_0_ID="{{ .STRIGO_RESOURCE_0_ID }}"
export STRIGO_RESOURCE_0_NAME="{{ .STRIGO_RESOURCE_0_NAME }}"
export STRIGO_RESOURCE_1_DNS="{{ .STRIGO_RESOURCE_1_DNS }}"
export STRIGO_RESOURCE_1_ID="{{ .STRIGO_RESOURCE_1_ID }}"
export STRIGO_RESOURCE_1_NAME="{{ .STRIGO_RESOURCE_1_NAME }}"
export STRIGO_RESOURCE_2_DNS="{{ .STRIGO_RESOURCE_2_DNS }}"
export STRIGO_RESOURCE_2_ID="{{ .STRIGO_RESOURCE_2_ID }}"
export STRIGO_RESOURCE_2_NAME="{{ .STRIGO_RESOURCE_2_NAME }}"
export KONG_PROXY_URI=$(echo "https://"{{ .STRIGO_WORKSPACE_ID }}"-"{{ .STRIGO_RESOURCE_0_ID }}".labs.strigo.io:8443" | tr '[:upper:]' '[:lower:]')
export KONG_ADMIN_API_URI=$(echo "https://"{{ .STRIGO_WORKSPACE_ID }}"-"{{ .STRIGO_RESOURCE_0_ID }}".labs.strigo.io:8444" | tr '[:upper:]' '[:lower:]')
export KONG_ADMIN_GUI_URL=$(echo "https://"{{ .STRIGO_WORKSPACE_ID }}"-"{{ .STRIGO_RESOURCE_0_ID }}".labs.strigo.io:8445" | tr '[:upper:]' '[:lower:]')
export KONG_PORTAL_GUI_HOST=$(echo ""{{ .STRIGO_WORKSPACE_ID }}"-"{{ .STRIGO_RESOURCE_0_ID }}".labs.strigo.io:8446" | tr '[:upper:]' '[:lower:]')
export KONG_PORTAL_API_URL=$(echo "https://"{{ .STRIGO_WORKSPACE_ID }}"-"{{ .STRIGO_RESOURCE_0_ID }}".labs.strigo.io:8447"  | tr '[:upper:]' '[:lower:]')
export KONG_COURSE_ID=$(echo "{{ .STRIGO_CLASS_NAME }}" | cut -d ' ' -f 1 | sed 's/\.//')
EOF

sed -i '/{{/d' $ENVF
sed -i '/undefined/d' $ENVF
chown ubuntu:ubuntu $ENVF
printf "%s\n" "$(cat $ENVF)" >> $LOG
sed -i 's/export //g' $LOG

source $ENVF

# Clone the edu-strigo-[infra|courses] repos to /tmp using deploy keys
ssh-keyscan -H github.com >> /root/.ssh/known_hosts
eval $(ssh-agent -s)
ssh-add /root/.ssh/strigo_init_deploy_key
printf "%s Cloning INFRA repo...\n" "$(date -u +$ISO8601)" >> $LOG
git clone -b dd/hotfix git@github.com:kong-education/edu-strigo-infra /tmp/edu-strigo-infra
eval $(ssh-agent -s)
ssh-add /root/.ssh/strigo_courses_deploy_key
printf "%s Cloning COURSES repo...\n" "$(date -u +$ISO8601)" >> $LOG
git clone -b dd/hotfix git@github.com:kong-education/edu-strigo-courses /tmp/edu-strigo-courses
find /tmp/edu-strigo-courses/ -name "INIT.sh" -exec rm {} \;

# Execute deployment script from the cloned repo
printf "%s Executing deploy.sh...\n" "$(date -u +$ISO8601)" >> $LOG
source /tmp/edu-strigo-infra/deploy.sh

# Remove NOPASSWD & assign password for user ubuntu
# External login through key, local sudo through password
printf "%s Applying PASSWD policy...\n" "$(date -u +$ISO8601)" >> $LOG
sed -e '/NOPASSWD/ s/^#*/#/' -i /etc/cloud/cloud.cfg
sed -e '/NOPASSWD/ s/\NOPASSWD\://g' -i /etc/sudoers.d/90-cloud-init-users
newgrp ubuntu
echo "ubuntu:123KongStrong!" | chpasswd