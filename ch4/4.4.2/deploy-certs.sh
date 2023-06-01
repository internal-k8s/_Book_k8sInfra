#!/usr/bin/env bash
host=192.168.1.10:8443
certs=/etc/docker/certs.d/$host
ca_store=/usr/local/share/ca-certificates/

mkdir -p /harbor-data
mkdir -p $certs

apt-get install sshpass -y
for i in {1..3}
  do
    sshpass -p vagrant scp -o StrictHostKeyChecking=no ca.crt 192.168.1.10$i:$ca_store
    sshpass -p vagrant ssh root@192.168.1.10$i update-ca-certificates && systemctl restart containerd
  done

cp ca.crt $certs
cp ca.crt $ca_store
mv $host.key /harbor-data
mv $host.crt /harbor-data
update-ca-certificates
systemctl restart containerd
