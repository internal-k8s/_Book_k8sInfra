#!/usr/bin/env bash

# init kubernetes 
kubeadm init --token 123456.1234567890123456 --token-ttl 0 \
             --skip-phases=addon/kube-proxy \
             --pod-network-cidr=172.16.0.0/16 \
             --apiserver-advertise-address=192.168.1.10 

# config for control-plane node only 
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# cilium install
curl -L --fail --remote-name-all https://github.com/sysnet4admin/BB/raw/refs/heads/main/cilium-cli/v0.16.19/cilium-linux-amd64.tar.gz
sudo tar xvfC cilium-linux-amd64.tar.gz /usr/local/bin

# config for kubernetes's network by cilium
cilium install \
  --version=v1.16.2 \
  --helm-set ipam.mode=kubernetes \
  --helm-set ipv4NativeRoutingCIDR="172.16.0.0/16" \
  --helm-set l2announcements.enabled="true" \
  --helm-set kubeProxyReplacement="true" \
  --helm-set externalIPs.enabled="true" \
  --helm-set hubble.enable="true"

# kubectl completion on bash-completion dir
kubectl completion bash > /etc/bash_completion.d/kubectl

# alias kubectl to k 
echo 'alias k=kubectl'               >> ~/.bashrc
echo "alias ka='kubectl apply -f'"   >> ~/.bashrc
echo "alias kg-po-ip-stat-no='kubectl get pods -o=custom-columns=\
NAME:.metadata.name,IP:.status.podIP,STATUS:.status.phase,NODE:.spec.nodeName'" \
                                     >> ~/.bashrc 
echo 'complete -F __start_kubectl k' >> ~/.bashrc

# git clone book source 
git clone https://github.com/internal-k8s/_Book_k8sInfra.git 
mv /home/vagrant/_Book_k8sInfra $HOME
find $HOME/_Book_k8sInfra -regex ".*\.\(sh\)" -exec chmod 700 {} \;

# make rerepo-Book-k8sInfra and input proper permission
cat <<EOF > /usr/local/bin/rerepo-Book_k8sInfra
#!/usr/bin/env bash
rm -rf $HOME/_Book_k8sInfra
git clone https://github.com/internal-k8s/_Book_k8sInfra.git $HOME/_Book_k8sInfra
find $HOME/_Book_k8sInfra -regex ".*\.\(sh\)" -exec chmod 700 {} \;
EOF
chmod 700 /usr/local/bin/rerepo-Book_k8sInfra
