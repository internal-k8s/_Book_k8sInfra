#!/usr/bin/env bash

# LoadBalancer 
kubectl apply -f ~/_Book_k8sInfra/ch3/3.3.2/metallb-native-v0.13.10.yaml
echo "Waiting 60secs for MetalLB CRD" ; sleep 60
kubectl apply -f ~/_Book_k8sInfra/ch3/3.3.2/metallb-l2-iprange.yaml

# StorageClass  
kubectl apply -f ~/_Book_k8sInfra/ch3/3.4.3/nfs-subdir-external-provisioner-v4.0.0.yaml
kubectl apply -f ~/_Book_k8sInfra/ch3/3.4.3/storageclass.yaml
bash ~/_Book_k8sInfra/ch3/3.4.3/nfs_exporter.sh "dynamic-vol"

# Helm & repo add 
bash ~/_Book_k8sInfra/ch5/5.2.3/install_helm.sh
bash ~/_Book_k8sInfra/ch5/5.2.3/helm_completion.sh
helm repo add edu https://k8s-edu.github.io/Bkv2_main/helm-charts

