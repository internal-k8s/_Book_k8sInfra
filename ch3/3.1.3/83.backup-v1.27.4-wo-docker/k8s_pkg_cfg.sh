#!/usr/bin/env bash

# Avoid 'dpkg-reconfigure: unable to re-open stdin: No file or directory'
export DEBIAN_FRONTEND=noninteractive

# update package list 
apt-get update 

# install NFS 
if [ $3 = 'CP' ]; then
  apt-get install nfs-server nfs-common -y 
elif [ $3 = 'W' ]; then
  apt-get install nfs-common -y 
fi

# install kubernetes
# both kubelet and kubectl will install by dependency
# but aim to latest version. so fixed version by manually
apt-get install -y kubelet=$1 kubectl=$1 kubeadm=$1 containerd.io=$2

# containerd configure to default and change cgroups to systemd 
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Fixed container runtime to containerd
#cat <<EOF > /etc/default/kubelet
#KUBELET_KUBEADM_ARGS=--container-runtime=remote \
#                     --container-runtime-endpoint=/run/containerd/containerd.sock \
#                     --cgroup-driver=systemd
#EOF

# Avoid WARN&ERRO(default endpoints) when crictl run  
#cat <<EOF > /etc/crictl.yaml
#runtime-endpoint: unix:///run/containerd/containerd.sock
#image-endpoint: unix:///run/containerd/containerd.sock
#EOF

# Ready to install for k8s 
systemctl restart containerd ; systemctl enable containerd
systemctl enable --now kubelet

# avoid kubelet.go:2424] "Error getting node" err="node \"cp-k8s\" not found"
# https://admantium.medium.com/kubernetes-with-kubeadm-cluster-installation-from-scratch-810adc1b0a64
apt-get install apparmor -y
