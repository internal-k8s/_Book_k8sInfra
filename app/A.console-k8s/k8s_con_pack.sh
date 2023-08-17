#!/usr/bin/env bash

# Avoid 'dpkg-reconfigure: unable to re-open stdin: No file or directory'
export DEBIAN_FRONTEND=noninteractive

# install util packages 
apt-get install sshpass

# add kubernetes repo ONLY for 22.04
mkdir -p /etc/apt/keyrings
curl -fsSL \
  https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg
echo \
  "deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] \
  https://apt.kubernetes.io/ kubernetes-xenial main" \
  | tee /etc/apt/sources.list.d/kubernetes.list

# update repo info 
apt-get update 

# install kubectl
apt-get install kubectl=$1 

# kubectl completion on bash-completion dir
kubectl completion bash >/etc/bash_completion.d/kubectl

# alias kubectl to k 
echo 'alias k=kubectl' >> ~/.bashrc
echo "alias ka='kubectl apply -f'" >> ~/.bashrc
echo "alias kd='kubectl delete -f'" >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc

# install helm 
DESIRED_VERSION=v3.12.0
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
