#!/bin/bash
echo "Provisioning docker image ${docker_image}" | tee /var/log/provision.log

export HOME="/home/cloudservice"

# cleanup previous deployment
docker stop front_end || true
docker rm front_end || true

docker-credential-gcr configure-docker

docker pull ${docker_image}

docker run -d \
  --name front_end \
  --restart always \
  -e QUOTE_SERVICE_URL=${quote_service_url} \
  -e NEWSFEED_SERVICE_URL=${newsfeed_service_url} \
  -e STATIC_URL=${static_url} \
  -e NEWSFEED_SERVICE_TOKEN="T1&eWbYXNWG1w1^YGKDPxAWJ@^et^&kX" \
  -p 8080:8080 \
  ${docker_image}
