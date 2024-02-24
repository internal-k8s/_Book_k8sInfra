#!/usr/bin/env bash
HARBOR_HOST=192.168.1.10:8443
DOCKER_CERT_STORE=/etc/docker/certs.d/$HARBOR_HOST
HOST_CERT_STORE=/usr/local/share/ca-certificates

echo "create Harbor data directory..."
mkdir -p /harbor-data

echo "create Docker certificate store..."
mkdir -p $DOCKER_CERT_STORE

echo "install sshpass for deploying certificate..."
apt-get install sshpass -y

echo "deploy certificate to worker nodes..."
for i in {1..3}
  do
    echo "deploy to node w$i-k8s"
    sshpass -p vagrant scp -o StrictHostKeyChecking=no \
	    ./ca.crt 192.168.1.10$i:$HOST_CERT_STORE/harbor_ca.crt
    sshpass -p vagrant ssh root@192.168.1.10$i \
	    update-ca-certificates 
    sshpass -p vagrant ssh root@192.168.1.10$i \
	    systemctl restart containerd
  done

echo "deploy certificate to control plane..."
cp ca.crt $DOCKER_CERT_STORE/ca.crt
cp ca.crt $HOST_CERT_STORE/harbor_ca.crt

echo "deploy private key and certificate to Harbor..."
mv server.key /harbor-data
mv server.crt /harbor-data
update-ca-certificates 
systemctl restart containerd
