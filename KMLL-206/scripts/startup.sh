#!/bin/bash

ENVF="/home/ubuntu/.envs"
cat << EOF | tee -a "$ENVF" /home/ubuntu/.profile > /dev/null
export KUBECONFIG="/home/ubuntu/.kube/config"
export KONG_MESH_DEMO_APP=http://$STRIGO_RESOURCE_DNS:31112
export KONG_MESH_ADMIN_API=http://$STRIGO_RESOURCE_DNS:30002
export KONG_MESH_GUI=http://$STRIGO_RESOURCE_DNS:30002/gui
export KONG_MESH_KIC=http://$STRIGO_RESOURCE_DNS:80
export GRAFANA_HOST=$(echo -n "$STRIGO_INSTANCE_ID-$STRIGO_RESOURCE_0_WEB_INTERFACE_1_ID.rp.strigo.io" | tr '[:upper:]' '[:lower:]')
EOF

source $ENVF
mkdir -p /home/ubuntu/$KONG_COURSE_ID
mkdir -p /home/ubuntu/.kube
cp -R /tmp/edu-strigo-courses/$KONG_COURSE_ID/scripts/* /home/ubuntu/$KONG_COURSE_ID/
cp -R /tmp/edu-strigo-courses/$KONG_COURSE_ID/artifacts/* /home/ubuntu/$KONG_COURSE_ID/
chown -R ubuntu:ubuntu /home/ubuntu/$KONG_COURSE_ID
chown -R ubuntu:ubuntu /home/ubuntu/.kube/

mkdir -p /etc/kong/ssl
chown -R root:ubuntu /etc/kong
chmod -R 775 /etc/kong

chmod 775 /usr/local/bin/kumactl
chown ubuntu:root /usr/local/bin/kumactl
chmod 775 /usr/local/bin/kuma-cp
chown ubuntu:root /usr/local/bin/kuma-cp
chmod 775 /usr/local/bin/kuma-dp
chown ubuntu:root /usr/local/bin/kuma-dp
chmod 775 /usr/local/bin/envoy
chown ubuntu:root /usr/local/bin/envoy
chmod 775 /usr/local/bin/coredns
chown ubuntu:root /usr/local/bin/coredns

for i in {0..0}; do
  DNS_NAME="STRIGO_RESOURCE_${i}_DNS"
  SEED=$(echo ${!DNS_NAME} | od -A n -t x1 | sed 's/ *//g' | tr -d '\n')
  HASH=$(echo -n $SEED | sha256sum | cut -d ' ' -f 1)
  certtool --generate-privkey --outfile /tmp/ca.pss --key-type=rsa --sec-param=high --seed=$HASH
  certtool --to-rsa --load-privkey /tmp/ca.pss --outfile /tmp/ca.key
  chmod 600 /tmp/ca.key
  ssh-keygen -y -f /tmp/ca.key >> /home/ubuntu/.ssh/authorized_keys
  rm /tmp/ca.pss /tmp/ca.key
done

ssh-keyscan -t rsa,dsa,ecdsa -H $STRIGO_RESOURCE_0_DNS >> /home/ubuntu/.ssh/known_hosts
chown ubuntu:ubuntu /home/ubuntu/.ssh/known_hosts 

cat << EOF >> /home/ubuntu/$KONG_COURSE_ID/hostsFile
$STRIGO_RESOURCE_0_DNS
EOF

chown ubuntu:ubuntu /home/ubuntu/$KONG_COURSE_ID/hostsFile
echo 'ubuntu ALL=(ALL) NOPASSWD: /usr/bin/systemctl' | sudo EDITOR='tee -a' visudo -f /etc/sudoers.d/91-strigo-users
usermod -a -G ubuntu kong

# PostOp
cd /home/ubuntu/$KONG_COURSE_ID
[[ -f "/home/ubuntu/$KONG_COURSE_ID/postup.sh" ]] && su - ubuntu "/home/ubuntu/$KONG_COURSE_ID/postup.sh"
# [[ -f "/home/ubuntu/$KONG_COURSE_ID/postup.sh" ]] && echo "source /home/ubuntu/$KONG_COURSE_ID/postup.sh" >> /home/ubuntu/.profile

# Cleanup
mv /home/ubuntu/$KONG_COURSE_ID/metadata.yaml /home/ubuntu
rm -fr /tmp/edu-strigo-courses
rm -fr /tmp/edu-strigo-infra
rm /home/ubuntu/startup.sh