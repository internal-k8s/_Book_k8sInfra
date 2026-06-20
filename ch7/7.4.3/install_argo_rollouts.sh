#!/usr/bin/env bash

if [[ "$(uname -m)" =~ ^(arm64|aarch64)$ ]]; then
  ARCH="arm64"
else
  ARCH="amd64"
fi

echo "Install Argo Rollouts controller, dashboard, and ArgoCD extension config."
kubectl apply -n cicd \
  -f ~/_Book_k8sInfra/ch7/7.4.3/install.yaml

echo "Wait for Argo Rollouts controller to be ready..."
kubectl rollout status deployment/argo-rollouts -n cicd --timeout=120s

echo "Wait for Argo Rollouts dashboard to be ready..."
kubectl rollout status deployment/argo-rollouts-dashboard -n cicd --timeout=120s

echo "Install kubectl argo rollouts plugin."
curl -sLo /usr/local/bin/kubectl-argo-rollouts \
  https://github.com/argoproj/argo-rollouts/releases/download/v1.7.2/kubectl-argo-rollouts-linux-${ARCH}
chmod +x /usr/local/bin/kubectl-argo-rollouts

echo "Restart argocd-server to apply extension config."
kubectl rollout restart deployment/argocd-server -n cicd
kubectl rollout status deployment/argocd-server -n cicd --timeout=120s

PLUGIN_VER="$(kubectl argo rollouts version --short 2>/dev/null)"
echo ""
echo "Argo Rollouts controller installed."
echo "kubectl argo rollouts plugin: $PLUGIN_VER"
echo "ArgoCD extension: ArgoCD UI → Application → 'Rollout' tab"
