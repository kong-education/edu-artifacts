#!/bin/bash

cat <<EOF > /home/ubuntu/initlab.sh
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
source /home/ubuntu/.envs
cd /home/ubuntu/$(echo "{{ .STRIGO_CLASS_NAME }}" | cut -d ' ' -f 1 | sed 's/\.//')
EOF

chmod 644 /home/ubuntu/initlab.sh
chown ubuntu:ubuntu /home/ubuntu/initlab.sh

# Write context variables to a file for persistence
cat <<EOF > /home/ubuntu/.envs
export STRIGO_EVENT_ID="{{ .STRIGO_EVENT_ID }}"
export STRIGO_EVENT_NAME="{{ .STRIGO_EVENT_NAME }}"
export STRIGO_CLASS_ID="{{ .STRIGO_CLASS_ID }}"
export STRIGO_CLASS_NAME="{{ .STRIGO_CLASS_NAME }}"
export STRIGO_USER_ID="{{ .STRIGO_USER_ID }}"
export STRIGO_USER_EMAIL="{{ .STRIGO_USER_EMAIL }}"
export STRIGO_USER_NAME="{{ .STRIGO_USER_NAME }}"
export STRIGO_ORG_ID="{{ .STRIGO_ORG_ID }}"
export STRIGO_ORG_NAME="{{ .STRIGO_ORG_NAME }}"
export STRIGO_PARTNER_ID="{{ .STRIGO_PARTNER_ID }}"
export STRIGO_PARTNER_NAME="{{ .STRIGO_PARTNER_NAME }}"
export STRIGO_WORKSPACE_ID="{{ .STRIGO_WORKSPACE_ID }}"
export STRIGO_WORKSPACE_FLAVOR="{{ .STRIGO_WORKSPACE_FLAVOR }}"
export STRIGO_RESOURCE_NAME="{{ .STRIGO_RESOURCE_NAME }}"
export STRIGO_RESOURCE_DNS="{{ .STRIGO_RESOURCE_DNS }}"
export STRIGO_EVENT_HOST_EMAIL="{{ .STRIGO_EVENT_HOST_EMAIL }}"
export STRIGO_RESOURCE_ID="{{ .STRIGO_RESOURCE_0_ID }}"
export FQDN=$(echo "{{ .STRIGO_RESOURCE_DNS }}" | tr '[:upper:]' '[:lower:]')
export KONG_COURSE_ID=$(echo "{{ .STRIGO_CLASS_NAME }}" | cut -d ' ' -f 1 | sed 's/\.//')
EOF

chown ubuntu:ubuntu /home/ubuntu/.envs

# Clone the edu-strigo-[infra|courses] repos to /tmp using deploy keys
ssh-keyscan -H github.com >> /root/.ssh/known_hosts
eval $(ssh-agent -s)
ssh-add /root/.ssh/strigo_init_deploy_key
git clone git@github.com:kong-education/edu-strigo-infra /tmp/edu-strigo-infra
eval $(ssh-agent -s)
ssh-add /root/.ssh/strigo_courses_deploy_key
git clone git@github.com:kong-education/edu-strigo-courses /tmp/edu-strigo-courses
find /tmp/edu-strigo-courses/ -name "INIT.sh" -exec rm {} \;

# Execute deployment script from the cloned repo
source /tmp/edu-strigo-infra/deploy.sh

# Remove NOPASSWD & assign password for user ubuntu
# External login through key, local sudo through password
sed -e '/NOPASSWD/ s/^#*/#/' -i /etc/cloud/cloud.cfg
sed -e '/NOPASSWD/ s/\NOPASSWD\://g' -i /etc/sudoers.d/90-cloud-init-users
echo "ubuntu:123KongStrong!" | chpasswd
newgrp ubuntu