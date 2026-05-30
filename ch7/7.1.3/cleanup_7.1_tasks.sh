#!/usr/bin/env bash

# uninstall app by helm 
helm uninstall prom 

# delete deployed apps 
kubectl delete deployment nginx-by-k8s-dash 
kubectl delete deployment nginx-by-headlamp 

# delete kubernetes-dashboard
kubectl delete -f $HOME/_Book_k8sInfra/ch7/7.1.2/kubernetes-dashboard.yaml

# delete viewer RBAC resources and kubeconfig context
kubectl delete clusterrolebinding viewer-binding
kubectl delete serviceaccount viewer -n default
kubectl config delete-context viewer-context
kubectl config delete-user viewer-user

