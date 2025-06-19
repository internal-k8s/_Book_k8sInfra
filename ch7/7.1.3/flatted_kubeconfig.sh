#!/usr/bin/env bash

# get kubeconfig from 192.168.1.10 (API Server) to current dir
sshpass -p vagrant scp -o StrictHostKeyChecking=no root@192.168.1.10:/root/.kube/config ./kubeconfig

# backup current context's config 
cp ~/.kube/config ~/tmp/kubeconfig-backup

# flatten .kube_config
export KUBECONFIG=~/tmp/kubeconfig-backup:./kubeconfig
kubectl config view --flatten > ~/.kube/config 

# clear downloaded kubeconfig 
rm ./kubeconfig 

echo "Successfully flatten kubeconfig"
