#!/usr/bin/env bash

# avoid 'dpkg-reconfigure: unable to re-open stdin: No file or directory'
export DEBIAN_FRONTEND=noninteractive

#yum install python36 python36-pip git -y
apt-get update && apt-get install python3-pip sshpass -y 

# git clone https://github.com/kubernetes-sigs/kubespray.git
# to avoid kubectl missing error and deploy v1.27.8 by release 2.23 
git clone -b release-2.23 https://github.com/kubernetes-sigs/kubespray.git
sudo mv kubespray /root

# other ansible, jinja2 netaddr will be installed by requirement.txt (2024.01.12)
#ansible==8.5.0
#cryptography==41.0.4
#jinja2==3.1.2
#jmespath==1.0.1
#MarkupSafe==2.1.3
#netaddr==0.9.0
#pbr==5.11.1
#ruamel.yaml==0.17.35
#ruamel.yaml.clib==0.2.8
pip3.10 install -r /root/kubespray/requirements.txt


cat <<EOF >  /root/kubespray/ansible_hosts.ini
[all]
cp11-k8s ansible_host=192.168.1.11 ip=192.168.1.11
cp12-k8s ansible_host=192.168.1.12 ip=192.168.1.12
cp13-k8s ansible_host=192.168.1.13 ip=192.168.1.13
w101-k8s ansible_host=192.168.1.101 ip=192.168.1.101
w102-k8s ansible_host=192.168.1.102 ip=192.168.1.102
w103-k8s ansible_host=192.168.1.103 ip=192.168.1.103
w104-k8s ansible_host=192.168.1.104 ip=192.168.1.104
w105-k8s ansible_host=192.168.1.105 ip=192.168.1.105
w106-k8s ansible_host=192.168.1.106 ip=192.168.1.106

[etcd]
cp11-k8s 
cp12-k8s 
cp13-k8s 

[kube-controlplane]
cp11-k8s 
cp12-k8s 
cp13-k8s 

[kube-worker]
w101-k8s 
w102-k8s 
w103-k8s 
w104-k8s 
w105-k8s 
w106-k8s 

[calico-rr]

[k8s-cluster:children]
kube-controlplane
etcd
kube-worker
calico-rr
EOF
