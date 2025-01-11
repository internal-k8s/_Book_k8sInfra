#!/usr/bin/env bash

# deploy nfs-provisioner & storageclass as default 
sh -c "$HOME/_Book_k8sInfra/ch3/3.4.3/nfs_exporter.sh dynamic-vol"
kubectl create -f $HOME/_Book_k8sInfra/ch3/3.4.3/nfs-subdir-external-provisioner-v4.0.0.yaml
kubectl create -f $HOME/_Book_k8sInfra/ch3/3.4.3/storageclass.yaml
kubectl annotate storageclass managed-nfs-storage storageclass.kubernetes.io/is-default-class=true

# config cilium layer2 mode 
(sleep 600 && kubectl apply -f $HOME/_Book_k8sInfra/ch7/7.1.1/k8s-extra-pkgs/cilium-l2-ippool.yaml)&

# install helm & add repo 
$HOME/_Book_k8sInfra/ch5/5.2.3/install_helm.sh
helm repo add edu https://k8s-edu.github.io/Bkv2_main/helm-charts/
