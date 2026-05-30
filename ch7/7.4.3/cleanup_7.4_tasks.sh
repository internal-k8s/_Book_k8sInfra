#!/usr/bin/env bash

echo "🧹 [7.4] ArgoCD / Argo Rollouts 실습 리소스 정리"

# 7.4.3 카나리 Rollout
kubectl delete rollout canary-nginx 2>/dev/null
kubectl delete service canary-nginx 2>/dev/null

# 7.4.2 블루그린 Rollout
kubectl delete rollout bluegreen-nginx 2>/dev/null
kubectl delete service bluegreen-active bluegreen-preview 2>/dev/null

# 7.4.2 Argo Rollouts 컨트롤러
kubectl delete namespace argo-rollouts 2>/dev/null

# 7.4.1 ArgoCD
kubectl delete namespace argocd 2>/dev/null

echo "✅ 7.4 cleanup done."
