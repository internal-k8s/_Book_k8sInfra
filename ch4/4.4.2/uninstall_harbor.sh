#!/usr/bin/env bash

TAG=v2.10.0
HARBOR_HOST=192.168.1.10:8443
DOCKER_CERT_STORE=/etc/docker/certs.d/$HARBOR_HOST
HOST_CERT_STORE=/usr/local/share/ca-certificates

echo "Stopping Harbor..."
docker compose -f harbor/docker-compose.yml down

echo "Remove Harbor & files..."
# preserve initial scripts
mv ./harbor/get_harbor.sh .
mv ./harbor/modify_config.sh .
rm -rf ./harbor
mkdir harbor
mv get_harbor.sh ./harbor
mv modify_config.sh ./harbor

echo "Removing Harbor images..."
docker rmi goharbor/redis-photon:$TAG \
goharbor/harbor-registryctl:$TAG \
goharbor/registry-photon:$TAG \
goharbor/nginx-photon:$TAG \
goharbor/harbor-log:$TAG \
goharbor/harbor-jobservice:$TAG \
goharbor/harbor-core:$TAG \
goharbor/harbor-portal:$TAG \
goharbor/harbor-db:$TAG \
goharbor/prepare:$TAG

echo "Removing deployed certificates..."
for i in {1..3}
  do
    echo "remove certificate on w$i-k8s"
    sshpass -p vagrant ssh -o StrictHostKeyChecking=no \
            root@192.168.1.10$i rm -rf $DOCKER_CERT_STORE
    sshpass -p vagrant ssh root@192.168.1.10$i \
            rm $HOST_CERT_STORE/harbor_ca.crt
    sshpass -p vagrant ssh root@192.168.1.10$i \
            update-ca-certificates -f
    sshpass -p vagrant ssh root@192.168.1.10$i \
            systemctl restart containerd
  done

echo "Remove deployed private key and certificate on control plane..."
rm -f ./harbor_pki/ca.crt ./harbor_pki/ca.key ./harbor_pki/server.csr
rm -rf /harbor-data
rm -rf $DOCKER_CERT_STORE
rm -f $HOST_CERT_STORE/harbor_ca.crt

echo "Restart control plane to load the init environment..."
update-ca-certificates -f
systemctl restart containerd
