#!/usr/bin/env bash

##### Addtional configuration for All-in-one >> replace to extra-k8s-pkgs
EXTRA_PKGS_ADDR="https://raw.githubusercontent.com/sysnet4admin/IaC/main/k8s/extra-pkgs/v1.32"

# deploy nfs-provisioner & storageclass as default 
sh -c "$HOME/_Book_k8sInfra/ch3/3.4.3/nfs_exporter.sh dynamic-vol"
kubectl create -f $HOME/_Book_k8sInfra/ch3/3.4.3/nfs-subdir-external-provisioner-v4.0.0.yaml
kubectl create -f $HOME/_Book_k8sInfra/ch3/3.4.3/storageclass.yaml
kubectl annotate storageclass managed-nfs-storage storageclass.kubernetes.io/is-default-class=true

# config cilium layer2 mode 
# split cilium CRD due to it cannot apply at once. 
# it looks like Operator limitation
# QA: 
# - 300sec can deploy but safety range is from 540 - 600 
(sleep 600 && kubectl apply -f $EXTRA_PKGS_ADDR/cilium-l2-ippool.yaml)&

# install helm & add repo 
$HOME/_Book_k8sInfra/ch5/5.2.3/install_helm.sh
helm repo add edu https://k8s-edu.github.io/Bkv2_main/helm-charts/

