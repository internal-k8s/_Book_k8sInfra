#!/usr/bin/env bash

# Setup nfs-provisioner for elasticsearch lab
sh -c "$HOME/_Book_k8sInfra/ch3/3.4.3/nfs_exporter.sh dynamic-vol"
kubectl create -f $HOME/_Book_k8sInfra/ch3/3.4.3/nfs-subdir-external-provisioner-v4.0.0.yaml
kubectl create -f $HOME/_Book_k8sInfra/ch3/3.4.3/storageclass.yaml
kubectl annotate storageclass managed-nfs-storage storageclass.kubernetes.io/is-default-class=true
# Setup loadbalancer
(sleep 540 && kubectl apply -f $HOME/_Book_k8sInfra/ch7/7.1.1/extra-k8s-packages/cilium/cilium-l2announcement-policy.yaml)&
(sleep 560 && kubectl apply -f $HOME/_Book_k8sInfra/ch7/7.1.1/extra-k8s-packages/cilium/cilium-loadbalancer-ip-pool.yaml)&
$HOME/_Book_k8sInfra/ch5/5.2.3/install_helm.sh
helm repo add edu-k8s https://k8s-edu.github.io/Bkv2_main/helm-charts/
helm install prometheus-stack edu/kube-prometheus-stack  \
--namespace=monitoring \
--create-namespace \
-f $HOME/_Book_k8sInfra/ch7/7.1.1/extra-k8s-packages/prometheus-operator/values.yaml