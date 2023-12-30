#!/usr/bin/env bash

# Fixed Internal-IP (temp) when eth1 could fix by autodetect calico 
cat <<EOF > /etc/default/kubelet
KUBELET_EXTRA_ARGS=--node-ip=192.168.1.10
EOF

# init kubernetes (w/ containerd)
kubeadm init --token 123456.1234567890123456 --token-ttl 0 \
             --pod-network-cidr=172.16.0.0/16 \
             --apiserver-advertise-address=192.168.1.10 \
             --cri-socket=unix:///run/containerd/containerd.sock

# config for control-plane node only 
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# install cilium-cli and add permisssion to execute 
curl -L https://github.com/sysnet4admin/BB/raw/main/cilium-cli/v0.14.6/cilium \
     -o /usr/local/bin/cilium
chmod 744 /usr/local/bin/cilium 
# config for kubernetes's network by cilium 
cilium install \
  --version=v1.14.5 \
    --helm-set ipam.mode=kubernetes \
    --helm-set ipv4NativeRoutingCIDR="172.16.0.0/16" \
    --helm-set enable-l2-announcements="true" \
    --helm-set kubeProxyReplacement="true" \
    --helm-set externalIPs="true"

# kubectl completion on bash-completion dir
kubectl completion bash >/etc/bash_completion.d/kubectl

# extra-pkg-install for below task.
# install helm cli
# Configure nfs-common and nfs-server for dynamic provisoning
# Install storageclass for elasticsearch

mkdir -p /nfs_shared/dynamic-vol
chmod -R 766 /nfs_shared/dynamic-vol/
echo "/nfs_shared/dynamic-vol 192.168.1.0/24(rw,sync,no_root_squash)" >> /etc/exports
systemctl enable nfs-kernel-server --now
systemctl restart nfs-kernel-server

# alias kubectl to k 
echo 'alias k=kubectl' >> ~/.bashrc
echo "alias ka='kubectl apply -f'" >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc

# git clone book source 
git clone https://github.com/internal-k8s/_Book_k8sInfra.git 
mv /home/vagrant/_Book_k8sInfra $HOME
find $HOME/_Book_k8sInfra -regex ".*\.\(sh\)" -exec chmod 700 {} \;

# make rerepo-k8s-learning.kit and put permission
cat <<EOF > /usr/local/bin/rerepo-book-k8sinfra
#!/usr/bin/env bash
rm -rf $HOME/_Book_k8sInfra
git clone https://github.com/internal-k8s/_Book_k8sInfra.git $HOME/_Book_k8sInfra
find $HOME/_Book_k8sInfra -regex ".*\.\(sh\)" -exec chmod 700 {} \;
EOF
chmod 700 /usr/local/bin/rerepo-book-k8sinfra

