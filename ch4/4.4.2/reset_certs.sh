#!/usr/bin/env bash
HARBOR_HOST=192.168.1.10:8443
DOCKER_CERT_STORE=/etc/docker/certs.d/$HARBOR_HOST
HOST_CERT_STORE=/usr/local/share/ca-certificates

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
apt-get remove sshpass -y
update-ca-certificates -f
systemctl restart containerd
