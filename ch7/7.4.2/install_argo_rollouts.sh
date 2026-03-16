#!/usr/bin/env bash

echo "🚀 Install Argo Rollouts controller."
kubectl create namespace argo-rollouts 2>/dev/null
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/download/v1.7.2/install.yaml

echo "⏳ Wait for Argo Rollouts controller to be ready..."
kubectl wait --for=condition=available deployment/argo-rollouts -n argo-rollouts --timeout=120s

echo ""
echo "✅ Argo Rollouts controller installed."
echo ""
echo "📌 kubectl plugin 설치 (선택):"
echo "   macOS:  brew install argoproj/tap/kubectl-argo-rollouts"
echo "   Linux:  curl -LO https://github.com/argoproj/argo-rollouts/releases/download/v1.7.2/kubectl-argo-rollouts-linux-amd64"
echo "           chmod +x kubectl-argo-rollouts-linux-amd64"
echo "           sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts"

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
