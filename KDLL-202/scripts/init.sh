#!/bin/bash

INFRABRANCH=refactor
COURSEBRANCH=jhn/from-gateway-3.10-upgrade/KDLL-202-labs
DEV_MODE=true

if [ "$DEV_MODE" = "true" ]; then
  echo "$foo"
  echo "eval $(ssh-agent -s)" >> /root/.bashrc
  echo "ssh-add /root/.ssh/strigo_courses_deploy_key" >> /root/.bashrc
  echo "ssh-add /root/.ssh/strigo_init_deploy_key" >> /root/.bashrc
  echo "ssh-add /root/.ssh/strigo_courses_deploy_key" >> /root/.bashrc

cat <<EOF > /root/restart_lab.sh
#!/bin/bash

source /home/ubuntu/.envs

mv /home/ubuntu/$KONG_COURSE_ID /home/ubuntu/$KONG_COURSE_ID.BAK
rm -rf /home/ubuntu/startup.sh
rm -rf /tmp/edu-strigo-courses
rm -rf /tmp/edu-strigo-apps

git clone -b $COURSEBRANCH git@github.com:kong-education/edu-strigo-courses /tmp/edu-strigo-courses
git clone -b $INFRABRANCH git@github.com:kong-education/edu-strigo-infra /tmp/edu-strigo-infra
git clone git@github.com:kong-education/edu-apps /tmp/edu-strigo-apps

source /home/ubuntu/startup.sh
EOF
chmod a+x /root/restart_lab.sh
fi

ENVF="/home/ubuntu/.envs"
TARRY=12

logger -i -p info -t STRIGO "INIT starting..."
logger -i -p info -t STRIGO "Setting HOSTNAME..."
FQDN=$(echo "{{ .STRIGO_RESOURCE_DNS }}" | tr '[:upper:]' '[:lower:]')
SHORTNAME=$(echo "$FQDN" | cut -d'.' -f1)
sed -i "1i127.0.1.1 $SHORTNAME" /etc/hosts
hostnamectl set-hostname $FQDN
hostnamectl set-location Kong Education Lab
hostnamectl set-icon-name KONG

logger -i -p info -t STRIGO "Restarting Services..."
systemctl restart systemd-hostnamed restart
systemctl restart systemd-networkd
systemctl restart rsyslog
systemctl restart ssh

logger -i -p info -t STRIGO "Creating newrelic Service & Log Configs..."
cat > /etc/newrelic-infra/logging.d/logs.yml << EOF
logs:
  - name: syslog
    file: /var/log/syslog
    attributes:
      logtype: syslog-rfc5424
      strigo_class_code: "$(echo "{{ .STRIGO_CLASS_NAME }}" | cut -d ' ' -f 1 | sed 's/\.//')"
      strigo_event_id: "{{ .STRIGO_EVENT_ID }}"
      strigo_user_email: "{{ .STRIGO_USER_EMAIL }}"
      strigo_workspace_flavor: "{{ .STRIGO_WORKSPACE_FLAVOR }}"
  - name: konglog
    file: /var/log/kong/*.log
    attributes:
      logtype: nginx
      strigo_class_code: "$(echo "{{ .STRIGO_CLASS_NAME }}" | cut -d ' ' -f 1 | sed 's/\.//')"
      strigo_event_id: "{{ .STRIGO_EVENT_ID }}"
      strigo_user_email: "{{ .STRIGO_USER_EMAIL }}"
      strigo_workspace_flavor: "{{ .STRIGO_WORKSPACE_FLAVOR }}"
EOF

cat >> /etc/newrelic-infra.yml << EOF
custom_attributes:
  strigo_class_code:  "$(echo "{{ .STRIGO_CLASS_NAME }}" | cut -d ' ' -f 1 | sed 's/\.//')"
  strigo_event_id: "{{ .STRIGO_EVENT_ID }}"
  strigo_user_email: "{{ .STRIGO_USER_EMAIL }}"
  strigo_workspace_flavor: "{{ .STRIGO_WORKSPACE_FLAVOR }}"
EOF

logger -i -p info -t STRIGO "Starting newrelic Service..."
systemctl enable --now newrelic-infra
sleep $((2*TARRY))

logger -i -p info -t STRIGO "Creating /home/ubuntu/start_lab.sh..."
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

[ -f "/home/ubuntu/post_startup.sh" ] && /home/ubuntu/post_startup.sh

echo -e "\nINIT script is done!"
sleep 2

source $ENVF
# source /home/ubuntu/.bashrc
cd /home/ubuntu/$(echo "{{ .STRIGO_CLASS_NAME }}" | cut -d ' ' -f 1 | sed 's/\.//')
EOF

chmod 644 /home/ubuntu/start_lab.sh
chown ubuntu:ubuntu /home/ubuntu/start_lab.sh

# Writing context variables to a file for persistence
logger -i -p info -t STRIGO "Writing context variables to ~/.envs for persistence..."
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
export STRIGO_INSTANCE_ID="{{ .STRIGO_INSTANCE_ID }}"
export STRIGO_RESOURCE_0_WEB_INTERFACE_0_ID="{{ .STRIGO_RESOURCE_0_WEB_INTERFACE_0_ID }}"
export STRIGO_RESOURCE_0_WEB_INTERFACE_1_ID="{{ .STRIGO_RESOURCE_0_WEB_INTERFACE_1_ID }}"
export KONG_ADMIN_GUI_URL=$(echo "https://"{{ .STRIGO_INSTANCE_ID }}"-"{{ .STRIGO_RESOURCE_0_WEB_INTERFACE_0_ID }}".rp.strigo.io" | tr '[:upper:]' '[:lower:]')
export KONG_PORTAL_GUI_HOST=$(echo ""{{ .STRIGO_INSTANCE_ID }}"-"{{ .STRIGO_RESOURCE_0_WEB_INTERFACE_1_ID }}".rp.strigo.io" | tr '[:upper:]' '[:lower:]')
EOF

sed -i '/{{/d' $ENVF
sed -i '/undefined/d' $ENVF
chown ubuntu:ubuntu $ENVF

while IFS= read -r line; do
  logger -i -p info -t STRIGO "$(echo $line | sed "s/export\ //g")"
done < "$ENVF"

# Remove NOPASSWD & assign password for user ubuntu
# External login through key, local sudo through password
logger -i -p info -t STRIGO "Applying PASSWD policy..."
sed -e '/NOPASSWD/ s/^#*/#/' -i /etc/cloud/cloud.cfg
sed -e '/NOPASSWD/ s/NOPASSWD://g' -i /etc/sudoers.d/90-cloud-init-users
echo "ubuntu:123KongStrong!" | chpasswd
newgrp ubuntu

# Clone the edu-strigo-[infra|apps|courses] repos to /tmp using deploy keys
ssh-keyscan -H github.com >> /root/.ssh/known_hosts

eval $(ssh-agent -s)
ssh-add /root/.ssh/strigo_init_deploy_key
logger -i -p info -t STRIGO "Cloning INFRA repo..."
git clone -b $INFRABRANCH git@github.com:kong-education/edu-strigo-infra /tmp/edu-strigo-infra

eval $(ssh-agent -s)
ssh-add /root/.ssh/strigo_apps_deploy_key
logger -i -p info -t STRIGO "Cloning APPS repo..."
git clone git@github.com:kong-education/edu-apps /tmp/edu-strigo-apps

eval $(ssh-agent -s)
ssh-add /root/.ssh/strigo_courses_deploy_key
logger -i -p info -t STRIGO "Cloning COURSES repo..."
git clone -b $COURSEBRANCH git@github.com:kong-education/edu-strigo-courses /tmp/edu-strigo-courses

# Execute deployment script from the cloned repo
logger -i -p info -t STRIGO "Executing deploy.sh..."
source /tmp/edu-strigo-infra/deploy.sh