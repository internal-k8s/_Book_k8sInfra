#!/usr/bin/env bash

# avoid 'dpkg-reconfigure: unable to re-open stdin: No file or directory'
export DEBIAN_FRONTEND=noninteractive

# swapoff -a to disable swapping
swapoff -a
# sed to comment the swap partition in /etc/fstab (Rmv blank)
sed -i.bak -r 's/(.+swap.+)/#\1/' /etc/fstab

# add kubernetes repo
curl \
  -fsSL https://pkgs.k8s.io/core:/stable:/v$2/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo \
  "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v$2/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

# add docker-ce repo with containerd
curl -fsSL \
  https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

# configure host-only interface (eth1) for Ubuntu 24.04
# Vagrant private_network does not auto-apply netplan on Ubuntu 24.04
HOSTNAME=$(hostname)
if [ "$HOSTNAME" = "cp-k8s" ]; then
  HOST_IP="192.168.1.10/24"
else
  NODE_NUM=$(echo "$HOSTNAME" | grep -o '[0-9]\+$')
  HOST_IP="192.168.1.10${NODE_NUM}/24"
fi
cat <<EOF > /etc/netplan/99-k8s-host-only.yaml
network:
  version: 2
  ethernets:
    eth1:
      addresses:
        - ${HOST_IP}
EOF
chmod 600 /etc/netplan/99-k8s-host-only.yaml
netplan apply
sleep 2

# packets traversing the bridge are processed by iptables for filtering
echo 1 > /proc/sys/net/ipv4/ip_forward
# enable br_filter for iptables 
modprobe br_netfilter

# local small dns & vagrant cannot parse and delivery shell code.
echo "127.0.0.1 localhost" > /etc/hosts # localhost name will use by calico-node
echo "192.168.1.10 cp-k8s" >> /etc/hosts
for (( i=1; i<=$1; i++  )); do echo "192.168.1.10$i w$i-k8s" >> /etc/hosts; done
