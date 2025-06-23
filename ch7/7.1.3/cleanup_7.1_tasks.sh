#!/usr/bin/env bash

# uninstall app by helm 
helm uninstall prom 

# delete deployed apps 
kubectl delete deployment nginx-k8s-dash 
kubectl delete deployment nginx-headlamp 

# delete kubernetes-dashboard
kubectl delete -f $HOME/_Book_k8sInfra/ch7/7.1.2/kubernetes-dashboard.yaml

