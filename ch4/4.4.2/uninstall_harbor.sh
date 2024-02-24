#!/usr/bin/env bash
TAG=v2.10.0

echo "stop harbor..."
docker compose -f harbor/docker-compose.yml down

echo "remove harbor..."
# preserve initial scripts
mv ./harbor/get_harbor.sh ./
mv ./harbor/modify_config.sh ./
rm -rf ./harbor/*
rm -rf /harbor-data
mv get_harbor.sh ./harbor
mv modify_config.sh ./harbor

echo "remove harbor images..."
docker rmi -f goharbor/redis-photon:$TAG \
goharbor/harbor-registryctl:$TAG \
goharbor/registry-photon:$TAG \
goharbor/nginx-photon:$TAG \
goharbor/harbor-log:$TAG \
goharbor/harbor-jobservice:$TAG \
goharbor/harbor-core:$TAG \
goharbor/harbor-portal:$TAG \
goharbor/harbor-db:$TAG \
goharbor/prepare:$TAG
