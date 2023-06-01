#!/usr/bin/env bash
host=192.168.1.10:8443
certs=/etc/docker/certs.d/$host
ca_store=/usr/local/share/ca-certificates
rm -rf $certs
rm -rf /harbor-data
rm $ca_store/ca.crt

apt install sshpass -y
for i in {1..3}
  do
    sshpass -p vagrant ssh -o StrictHostKeyChecking=no root@192.168.1.10$i rm -rf $certs
    sshpass -p vagrant ssh root@192.168.1.10$i rm $ca_store/ca.crt
    sshpass -p vagrant ssh root@192.168.1.10$i update-ca-certificates && systemctl restart containerd
  done

apt-get remove sshpass -y
update-ca-certificates
systemctl restart containerd
