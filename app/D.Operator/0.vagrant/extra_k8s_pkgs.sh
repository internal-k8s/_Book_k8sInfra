#!/usr/bin/env bash

# Setup nfs-provisioner for elasticsearch lab
sh -c "$HOME/_Book_k8sInfra/ch3/3.4.3/nfs_exporter.sh dynamic-vol"
kubectl create -f $HOME/_Book_k8sInfra/ch3/3.4.3/nfs-subdir-external-provisioner-v4.0.0.yaml
kubectl create -f $HOME/_Book_k8sInfra/ch3/3.4.3/storageclass.yaml
kubectl annotate storageclass managed-nfs-storage storageclass.kubernetes.io/is-default-class=true
# Setup loadbalancer
(sleep 540 && kubectl apply -f $HOME/_Book_k8sInfra/app/D.Operator/0.vagrant/extra-k8s-packages/cilium-l2announcement-policy.yaml)
(sleep 560 && kubectl apply -f $HOME/_Book_k8sInfra/app/D.Operator/0.vagrant/extra-k8s-packages/cilium-loadbalancer-ip-pool.yaml)