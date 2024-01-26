#!/usr/bin/env bash

# avoid 'dpkg-reconfigure: unable to re-open stdin: No file or directory'
export DEBIAN_FRONTEND=noninteractive

#yum install python36 python36-pip git -y
apt-get update && apt-get install python3-pip sshpass -y 

# git clone https://github.com/kubernetes-sigs/kubespray.git
# to avoid kubectl missing error and deploy v1.27.9 by release 2.23
git clone -b release-2.23 https://github.com/kubernetes-sigs/kubespray.git
sudo mv kubespray /root

# other ansible, jinja2 netaddr will be installed by requirement.txt (2024.01.12)
#ansible==7.6.0
#cryptography==41.0.4
#jinja2==3.1.2
#jmespath==1.0.1
#MarkupSafe==2.1.3
#netaddr==0.9.0
#pbr==5.11.1
#ruamel.yaml==0.17.35
#ruamel.yaml.clib==0.2.8

# WARNING: Running pip as the 'root' user can result in broken permissions and conflicting behaviour with the system package manager. 
# It is recommended to use a virtual environment instead: https://pip.pypa.io/warnings/venv
# so stderr(2) to /dev/null 
pip3.10 install -r /root/kubespray/requirements.txt 2> /dev/null


cat <<EOF >  /root/kubespray/ansible_hosts.ini
[all]
cp11-k8s ansible_host=192.168.1.11 ip=192.168.1.11 etcd_member_name=etcd11
w101-k8s ansible_host=192.168.1.101 ip=192.168.1.101

[kube_control_plane]
cp11-k8s 

[etcd]
cp11-k8s 

[kube_node]
w101-k8s 

[calico_rr]

[k8s_cluster:children]
kube_control_plane
kube_node
calico_rr
EOF
