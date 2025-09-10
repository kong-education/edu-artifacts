#!/bin/bash

ENVF="/home/ubuntu/.envs"
cat << EOF | tee -a "$ENVF" /home/ubuntu/.profile > /dev/null
export KUBECONFIG="/home/ubuntu/.kube/config"
export KONG_MESH_ADMIN_API=http://$STRIGO_RESOURCE_0_DNS:30002
export KONG_MESH_GUI=http://$STRIGO_RESOURCE_0_DNS:30002/gui
export KONG_MESH_KIC=http://$STRIGO_RESOURCE_1_DNS:80
export KONG_MESH_GATEWAY=http://$STRIGO_RESOURCE_2_DNS:8080
EOF

source $ENVF
mkdir -p /home/ubuntu/$KONG_COURSE_ID
mkdir -p /home/ubuntu/.kube
cp -R /tmp/edu-strigo-courses/$KONG_COURSE_ID/scripts/* /home/ubuntu/$KONG_COURSE_ID/
cp -R /tmp/edu-strigo-courses/$KONG_COURSE_ID/artifacts/* /home/ubuntu/$KONG_COURSE_ID/
chown -R ubuntu:ubuntu /home/ubuntu/$KONG_COURSE_ID
chown -R ubuntu:ubuntu /home/ubuntu/.kube/

touch /etc/systemd/system/kuma-cp.service
chmod 666 /etc/systemd/system/kuma-cp.service
touch /etc/systemd/system/kuma-ingress.service
chmod 666 /etc/systemd/system/kuma-ingress.service
touch /etc/systemd/system/kuma-egress.service
chmod 666 /etc/systemd/system/kuma-egress.service
touch /etc/systemd/system/kuma-dp.service
chmod 666 /etc/systemd/system/kuma-dp.service
touch /etc/systemd/system/kuma-redis.service
chmod 666 /etc/systemd/system/kuma-redis.service
touch /etc/systemd/system/kuma-gateway.service
chmod 666 /etc/systemd/system/kuma-gateway.service

mkdir -p /var/log/kong
touch /var/log/kong/kuma-cp.log
touch /var/log/kong/kuma-cp.stdout
touch /var/log/kong/kuma-dp.log
touch /var/log/kong/kuma-dp.stdout
touch /var/log/kong/kuma-ingress.log
touch /var/log/kong/kuma-ingress.stdout
touch /var/log/kong/kuma-egress.log
touch /var/log/kong/kuma-egress.stdout
touch /var/log/kong/kuma-gateway.log
touch /var/log/kong/kuma-gateway.stdout
chown -R root:ubuntu /var/log/kong
chmod -R 775 /var/log/kong


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



for i in {0..2}; do
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
ssh-keyscan -t rsa,dsa,ecdsa -H $STRIGO_RESOURCE_1_DNS >> /home/ubuntu/.ssh/known_hosts
ssh-keyscan -t rsa,dsa,ecdsa -H $STRIGO_RESOURCE_2_DNS >> /home/ubuntu/.ssh/known_hosts
chown ubuntu:ubuntu /home/ubuntu/.ssh/known_hosts 

cat << EOF >> /home/ubuntu/$KONG_COURSE_ID/hostsFile
$STRIGO_RESOURCE_0_DNS
$STRIGO_RESOURCE_1_DNS
$STRIGO_RESOURCE_2_DNS
EOF

chown ubuntu:ubuntu /home/ubuntu/$KONG_COURSE_ID/hostsFile
echo 'ubuntu ALL=(ALL) NOPASSWD: /usr/bin/systemctl' | sudo EDITOR='tee -a' visudo -f /etc/sudoers.d/91-strigo-users
useradd -u 5678 -U kuma-dp
usermod -a -G ubuntu kuma-dp
usermod -a -G ubuntu kong

# Cleanup
mv /home/ubuntu/$KONG_COURSE_ID/metadata.yaml /home/ubuntu
rm -fr /tmp/edu-strigo-courses
rm -fr /tmp/edu-strigo-infra
rm /home/ubuntu/startup.sh