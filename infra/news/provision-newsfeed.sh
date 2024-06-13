#!/bin/bash
echo "Provisioning docker image ${docker_image}" | tee /var/log/provision.log

export HOME="/home/cloudservice"

# cleanup previous deployment
docker stop newsfeed || true
docker rm newsfeed || true

docker-credential-gcr configure-docker

docker pull ${docker_image}

docker run -d \
  --name newsfeed \
  --restart always \
  -p 8081:8081 \
  ${docker_image}
