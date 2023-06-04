#!/usr/bin/env bash

# create .kube_config dir
mkdir ~/.kube

# copy kubeconfig by sshpass
sshpass -p 'vagrant' scp -o StrictHostKeyChecking=no root@192.168.1.10:/etc/kubernetes/admin.conf ~/.kube/config 

# git clone Book-k8sinfra code 
git clone https://github.com/internal-k8s/_Book_k8sinfra.git $HOME/_Book_k8sinfra
find $HOME/_Book_k8sinfra -regex ".*\.\(sh\)" -exec chmod 700 {} \;

# make rerepo-Book-k8sinfra and input proper permission
cat <<EOF > /usr/local/bin/rerepo-Book_k8sinfra
#!/usr/bin/env bash
rm -rf $HOME/_Book_k8sinfra
git clone https://github.com/internal-k8s/_Book_k8sinfra.git $HOME/_Book_k8sinfra
find $HOME/_Book_k8sinfra -regex ".*\.\(sh\)" -exec chmod 700 {} \;
EOF
chmod 700 /usr/local/bin/rerepo-Book_k8sinfra
