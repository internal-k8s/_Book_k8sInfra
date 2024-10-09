#!/usr/bin/env bash

# avoid 'dpkg-reconfigure: unable to re-open stdin: No file or directory'
export DEBIAN_FRONTEND=noninteractive

# root_home_k8s_config 
va_k8s_cfg="/root/.kube/config" 

# add kubernetes repo
curl \
  -fsSL https://pkgs.k8s.io/core:/stable:/v$5/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo \
  "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v$5/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

# update repo info 
apt-get update 

# install kubectl
apt-get install kubectl=$1 -y 

# kubectl completion on bash-completion dir due to completion already installed 
kubectl completion bash >/etc/bash_completion.d/kubectl

# create .kube_config dir
mkdir /root/.kube

# copy hosts file by sshpass
sshpass -p 'vagrant' scp -o StrictHostKeyChecking=no root@192.168.1.$2:/etc/hosts /tmp/$2-hosts
sshpass -p 'vagrant' scp -o StrictHostKeyChecking=no root@192.168.1.$3:/etc/hosts /tmp/$3-hosts
sshpass -p 'vagrant' scp -o StrictHostKeyChecking=no root@192.168.1.$4:/etc/hosts /tmp/$4-hosts
cat /tmp/$2-hosts >> /etc/hosts; cat /tmp/$3-hosts >> /etc/hosts; cat /tmp/$4-hosts >> /etc/hosts

# copy kubeconfig by sshpass
sshpass -p 'vagrant' scp -o StrictHostKeyChecking=no root@192.168.1.$2:/root/.kube/config $va_k8s_cfg-$2
sshpass -p 'vagrant' scp -o StrictHostKeyChecking=no root@192.168.1.$3:/root/.kube/config $va_k8s_cfg-$3
sshpass -p 'vagrant' scp -o StrictHostKeyChecking=no root@192.168.1.$4:/root/.kube/config $va_k8s_cfg-$4

# flatten .kube_config 
export KUBECONFIG=$va_k8s_cfg-$2:$va_k8s_cfg-$3:$va_k8s_cfg-$4
kubectl config view --flatten > $va_k8s_cfg 

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

