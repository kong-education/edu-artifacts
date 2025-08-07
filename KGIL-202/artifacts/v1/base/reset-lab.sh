#!/usr/bin/env bash


source ~/.envs
CURRENTDIR=$(pwd)

cd /home/ubuntu/$KONG_COURSE_ID

# Teardown
./base/teardown.sh

# Install
./base/install.sh

# Patch
./base/patch.sh

# Deploy Docker Containers
# cd /home/ubuntu/$KONG_COURSE_ID/docker-containers
# docker-compose up -d

# Change back to directory
cd $CURRENTDIR

echo ""
echo System is Ready