#!/usr/bin/env bash

# Avoid 'dpkg-reconfigure: unable to re-open stdin: No file or directory'
export DEBIAN_FRONTEND=noninteractive

# install util packages 
apt-get install sshpass

# add kubernetes repo
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
curl -fsSL https://raw.githubusercontent.com/sysnet4admin/IaC/main/k8s/extra-pkgs/v1.35/get_helm_v4.0.4.sh \
  | DESIRED_VERSION=v4.1.3 bash
