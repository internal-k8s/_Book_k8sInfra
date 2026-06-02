#!/usr/bin/env bash

echo "Deploy ArgoCD to argocd namespace."
kubectl create ns argocd
kubectl apply --server-side --force-conflicts -n argocd \
  -f $HOME/_Book_k8sInfra/ch7/7.4.1/install.yaml

echo "Wait for ArgoCD to be ready..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=180s

echo "Expose ArgoCD server as LoadBalancer."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

PASSWORD="$(kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
ENDPOINT="$(kubectl get service argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"

echo ""
echo "ArgoCD UI:      http://$ENDPOINT"
echo "Admin password: $PASSWORD"
