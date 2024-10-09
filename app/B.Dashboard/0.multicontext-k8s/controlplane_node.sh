#!/usr/bin/env bash

# https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta4/
# experimental API spec: "kubeadm.k8s.io/v1beta4" is not allowed. You can use the --allow-experimental-api flag if the command supports it.
# https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta3/
#
# create config.yaml 
cat <<EOF > /tmp/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
bootstrapTokens:
- token: "123456.1234567890123456"
  description: "default kubeadm bootstrap token"
  ttl: "0"
localAPIEndpoint:
  advertiseAddress: 192.168.1.$1
  bindPort: 6443
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
clusterName: cluster-$2
networking:
  podSubnet: 172.16.0.0/16
EOF

# fixed Internal-IP  
cat <<EOF > /etc/default/kubelet
KUBELET_EXTRA_ARGS=--node-ip=192.168.1.$1
EOF

# init kubernetes from --config due to clusterName
#kubeadm init --config=/tmp/kubeadm-config.yaml --upload-certs 
kubeadm init --config=/tmp/kubeadm-config.yaml

##### Finished clsuter configuration #####

# config for control-plane node only 
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# CNI raw address & config for kubernetes's network 
CNI_ADDR="https://raw.githubusercontent.com/sysnet4admin/IaC/master/k8s/CNI"
kubectl apply -f $CNI_ADDR/172.16_net_calico_v3.26.0.yaml

# kubectl completion on bash-completion dir
kubectl completion bash >/etc/bash_completion.d/kubectl

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

# run lastly due to avoid this issue 
## bk8s-cp: error: cannot rename the context "kubernetes-admin@cluster-bk8s", it's not in /root/.kube/config
## bk8s-cp: sed: can't read /root/.kube/config: No such file or directory

# change context name from original to each cluster
kubectl config rename-context kubernetes-admin@cluster-$2 $2

# change user name from original to each cluster
sed -i "s,kubernetes-admin,$2-admin,g" $HOME/.kube/config
