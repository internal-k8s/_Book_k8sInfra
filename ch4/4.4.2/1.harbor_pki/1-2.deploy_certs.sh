#!/usr/bin/env bash

HARBOR_HOST=192.168.1.10:8443
DOCKER_CERT_DIR=/etc/docker/certs.d/$HARBOR_HOST
HOST_CERT_DIR=/usr/local/share/ca-certificates

# if 4.4.1 skipped, it should run. so add here. 
apt-get install sshpass -y > /dev/null 2>&1

echo "[Step 1/5] Create Harbor data directory..."
mkdir -p /harbor-data

echo "[Step 2/5] Create Docker certificate store..."
mkdir -p $DOCKER_CERT_DIR

echo "[Step 3/5] Deploy certificate to worker nodes..."
for i in {1..3}
  do
    echo "Deploy to node w$i-k8s"
    sshpass -p vagrant scp -o StrictHostKeyChecking=no \
	    ./ca.crt 192.168.1.10$i:$HOST_CERT_DIR/harbor_ca.crt
    sshpass -p vagrant ssh root@192.168.1.10$i \
	    update-ca-certificates 
    sshpass -p vagrant ssh root@192.168.1.10$i \
	    systemctl restart containerd
  done

echo "[Step 4/5] Deploy certificate to control plane..."
cp ca.crt $DOCKER_CERT_DIR/ca.crt
cp ca.crt $HOST_CERT_DIR/harbor_ca.crt

echo "[Step 5/5] Deploy private key and certificate to Harbor..."
mv server.key /harbor-data
mv server.crt /harbor-data
update-ca-certificates 
systemctl restart containerd
