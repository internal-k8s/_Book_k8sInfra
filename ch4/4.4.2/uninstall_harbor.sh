#!/usr/bin/env bash

TAG=v2.10.0
HARBOR_HOST=192.168.1.10:8443
DOCKER_CERT_DIR=/etc/docker/certs.d/$HARBOR_HOST
HOST_CERT_DIR=/usr/local/share/ca-certificates

echo "[Step 1/6] Stopping Harbor"
docker compose -f 2.harbor/docker-compose.yml down

echo "[Step 2/6] Remove Harbor & files"
# preserve initial scripts
mv ./2.harbor/2-1.get_harbor.sh .
mv ./2.harbor/2-2.modify_config.sh .
rm -rf ./2.harbor
mkdir 2.harbor
mv 2-1.get_harbor.sh ./2.harbor
mv 2-2.modify_config.sh ./2.harbor

echo "[Step 3/6] Removing Harbor images"
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

echo "[Step 4/6] Removing copied certificates"
for i in {1..3}
  do
    echo "remove certificate on w$i-k8s"
    sshpass -p vagrant ssh -o StrictHostKeyChecking=no \
            root@192.168.1.10$i rm -rf $DOCKER_CERT_DIR
    sshpass -p vagrant ssh root@192.168.1.10$i \
            rm $HOST_CERT_DIR/harbor_ca.crt
    sshpass -p vagrant ssh root@192.168.1.10$i \
            update-ca-certificates -f
    sshpass -p vagrant ssh root@192.168.1.10$i \
            systemctl restart containerd
  done

echo "[Step 5/6] Remove copied key and certificate from others components"
rm -f ./1.harbor_pki/ca.crt ./1.harbor_pki/ca.key ./1.harbor_pki/server.csr
rm -rf /harbor-data
rm -rf $DOCKER_CERT_DIR
rm -f $HOST_CERT_DIR/harbor_ca.crt

echo "[Step 6/6] Restart control plane to load the init environment"
update-ca-certificates -f
systemctl restart containerd
