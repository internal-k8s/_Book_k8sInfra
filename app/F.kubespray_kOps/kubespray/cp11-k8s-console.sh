#!/usr/bin/env bash

# avoid 'dpkg-reconfigure: unable to re-open stdin: No file or directory'
export DEBIAN_FRONTEND=noninteractive

# kubectl completion on bash-completion dir
#kubectl completion bash >/etc/bash_completion.d/kubectl

# alias kubectl to k 
echo 'alias k=kubectl'               >> ~/.bashrc
echo "alias ka='kubectl apply -f'"   >> ~/.bashrc
echo "alias kg-po-ip-stat-no='kubectl get pods -o=custom-columns=\
NAME:.metadata.name,IP:.status.podIP,STATUS:.status.phase,NODE:.spec.nodeName'" \
                                     >> ~/.bashrc 
echo 'complete -F __start_kubectl k' >> ~/.bashrc

