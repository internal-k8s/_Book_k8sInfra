#!/usr/bin/env bash

if [[ "$(uname -m)" =~ ^(arm64|aarch64)$ ]]; then
  ARCH="arm64"
else
  ARCH="amd64"
fi

echo "🚀 Install Argo Rollouts controller."
kubectl create namespace argo-rollouts 2>/dev/null
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/download/v1.7.2/install.yaml

echo "⏳ Wait for Argo Rollouts controller to be ready..."
kubectl wait --for=condition=available deployment/argo-rollouts -n argo-rollouts --timeout=120s

echo ""
echo "✅ Argo Rollouts controller installed."
echo ""
echo "🔧 Install kubectl argo rollouts plugin."
curl -sLo /usr/local/bin/kubectl-argo-rollouts \
  https://github.com/argoproj/argo-rollouts/releases/download/v1.7.2/kubectl-argo-rollouts-linux-${ARCH}
chmod +x /usr/local/bin/kubectl-argo-rollouts

PLUGIN_VER="$(kubectl argo rollouts version --short 2>/dev/null)"
echo "✅ kubectl argo rollouts plugin installed: $PLUGIN_VER"

echo ""
echo "🚀 Deploy Blue-Green Rollout."
kubectl apply -f $HOME/_Book_k8sInfra/ch7/7.4.2/bluegreen-rollout.yaml

echo "⏳ Wait for Rollout to be ready..."
kubectl wait --for=condition=available rollout/bluegreen-nginx --timeout=120s 2>/dev/null || sleep 10

ACTIVE_IP="$(kubectl get svc bluegreen-active -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
PREVIEW_IP="$(kubectl get svc bluegreen-preview -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
echo ""
echo "✅ Blue-Green Rollout deployed."
echo "   Active (현재):  http://$ACTIVE_IP"
echo "   Preview (신규): http://$PREVIEW_IP"
