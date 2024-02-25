#!/usr/bin/env bash
TAG=v2.10.0
HARBOR_HOST=192.168.1.10:8443
DOCKER_CERT_STORE=/etc/docker/certs.d/$HARBOR_HOST
HOST_CERT_STORE=/usr/local/share/ca-certificates

echo "stop harbor..."
docker compose -f harbor/docker-compose.yml down

echo "remove harbor..."
rm -rf ./harbor
rm -rf /harbor-data

echo "remove harbor images..."
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

echo "remove deployed certificate..."
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

echo "remove deployed private key and certificate on control plane..."
rm -f /harbor-data/server.* ./ca.* ./server.csr
rm -rf $DOCKER_CERT_STORE
rm -f $HOST_CERT_STORE/harbor_ca.crt

echo "reset control plane environment..."
update-ca-certificates -f
systemctl restart containerd
