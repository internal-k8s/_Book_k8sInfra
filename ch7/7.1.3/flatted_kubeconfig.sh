#!/usr/bin/env bash

# sshpass check and installation 
if command -v sshpass >/dev/null 2>&1; then
    :
else
    brew install sshpass
fi

# get kubeconfig from 192.168.1.10 (API Server) to current dir
sshpass -p vagrant scp -o StrictHostKeyChecking=no root@192.168.1.10:/root/.kube/config ./kubeconfig

# backup current context's config or create dummy
if [ ! -f "~/.kube/config" ]; then
  touch ~/.kube/config 
else
  cp ~/.kube/config ~/tmp/kubeconfig-backup
fi 

# flatten .kube_config
export KUBECONFIG=~/tmp/kubeconfig-backup:./kubeconfig
kubectl config view --flatten > ~/.kube/config 

# clear downloaded kubeconfig 
rm ./kubeconfig 

echo "Successfully flatten kubeconfig"
