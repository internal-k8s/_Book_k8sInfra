#!/usr/bin/env bash

echo "🚀 Deploy argocd to argocd namespace."
kubectl create ns argocd && kubectl apply -n argocd -f $HOME/_Book_k8sInfra/ch7/7.4.1/install.yaml

echo "🔧 Expose service to access argocd web ui on your browser!."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

PASSWORD="$(kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
echo "🔒 Admin initial password is $PASSWORD"
