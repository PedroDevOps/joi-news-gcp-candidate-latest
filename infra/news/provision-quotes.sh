#!/bin/bash
echo "Provisioning docker image ${docker_image}" | tee /var/log/provision.log

export HOME="/home/cloudservice"
# cleanup previous deployment
docker stop quotes || true
docker rm quotes || true

docker-credential-gcr configure-docker

docker pull ${docker_image}

docker run -d \
  --name quotes \
  --restart always \
  -p 8082:8082 \
  ${docker_image}
