#!/bin/bash

source benchmark-scripts/general-helper.sh
source benchmark-scripts/docker-helper.sh
mark_start
mount_fs
randomd
enable_network
rm -rf /run/docker* /var/run/docker*
docker_start
sleep 5;
docker run hello-world;
docker system prune --all --force;
write_modules
mark_end
