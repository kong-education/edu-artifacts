#!/bin/bash

# For testing
touch /home/ubuntu/.initcomplete
exit 0

source /home/ubuntu/.envs

#================================================#
#       Setting Environment Variables            #
#================================================#

KIND_HOST=$(http get 169.254.169.254/latest/meta-data/local-ipv4)

cat <<EOF >> /home/ubuntu/.envs
export KIND_HOST=$KIND_HOST
export KONNECT_GATEWAY=$STRIGO_RESOURCE_DNS:8000
EOF

cp -R /tmp/edu-strigo-courses/$KONG_COURSE_ID/artifacts/KIC_env_vars.sh /home/ubuntu/$KONG_COURSE_ID/
cat /home/ubuntu/$KONG_COURSE_ID/KIC_env_vars.sh >> /home/ubuntu/.envs
#Source the environment variables
source /home/ubuntu/.envs

#=======================================#
#       Configuring course files        #
#=======================================#

COURSEDIR="/home/ubuntu/$KONG_COURSE_ID"
mkdir -p "$COURSEDIR"

# chown -R ubuntu:ubuntu /home/ubuntu/$KONG_COURSE_ID

# This is the file the student runs to start the lab
# cp /tmp/edu-strigo-courses/scripts/$KONG_COURSE_ID/start_lab.sh /home/ubuntu/
# chmod u+x /home/ubuntu/start_lab.sh
cp /tmp/edu-strigo-courses/$KONG_COURSE_ID/scripts/configure.sh /home/ubuntu/
chmod u+x /home/ubuntu/configure.sh

# We should narrow this content down to just whats required
# cp -R /tmp/edu-strigo-courses/$KONG_COURSE_ID/artifacts/* /home/ubuntu/$KONG_COURSE_ID

chown -R ubuntu:ubuntu "$COURSEDIR"

# This isn't best logic, but we need that data into that file
# Need to be careful of dups here

cp -R /tmp/edu-strigo-courses/$KONG_COURSE_ID/artifacts/nginx /home/ubuntu/$KONG_COURSE_ID/

#================#
# Configure Kind #
#================#
cp -R /tmp/edu-strigo-courses/$KONG_COURSE_ID/artifacts/kind /home/ubuntu/$KONG_COURSE_ID/
yq -i '.networking.apiServerAddress = env(KIND_HOST)' /home/ubuntu/$KONG_COURSE_ID/kind/kind-config.yaml

#=============================#
# Copy Over Helm Values Files #
#=============================#

cp -R /tmp/edu-strigo-courses/$KONG_COURSE_ID/artifacts/helm /home/ubuntu/$KONG_COURSE_ID/


# chown -R ubuntu:ubuntu /home/ubuntu/$KONG_COURSE_ID
# # These need to have root permissions
# mkdir -p /usr/local/kong/
# cp /tmp/edu-strigo-infra/docker/nginx-kong.conf /usr/local/kong/
# cp /tmp/edu-strigo-infra/docker/nginx-kong-gui-include.conf /usr/local/kong/
# chown root:root /usr/local/kong/nginx*

# mkdir -p $COURSEDIR/misc
# mv /tmp/edu-strigo-infra/docker/nginx-kong.conf $COURSEDIR/misc/
# mv /tmp/edu-strigo-infra/docker/nginx-kong-gui-include.conf $COURSEDIR/misc/


#================================================#
#  Cleanup                                       #
#================================================#

# rm -f /home/ubuntu/$KONG_COURSE_ID/KIC_env_vars.sh
# rm -f /home/ubuntu/$KONG_COURSE_ID/commands
# rm -f /home/ubuntu/$KONG_COURSE_ID/docker-containers
# rm -f /home/ubuntu/$KONG_COURSE_ID/exercises
# rm -rf /tmp/edu-strigo-courses
# rm -rf /home/ubuntu/startup.sh

touch /home/ubuntu/.initcomplete
chmod a+w /home/ubuntu/.initcomplete
# Must be writable by Ubuntu user as script called by student in KGIL-201