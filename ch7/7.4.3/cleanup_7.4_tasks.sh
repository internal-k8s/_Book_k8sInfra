#!/usr/bin/env bash

echo "🧹 [7.4] ArgoCD / Argo Rollouts 실습 리소스 정리"

# 7.4.3 카나리 Rollout 삭제
kubectl delete -f $HOME/_Book_k8sInfra/ch7/7.4.3/ro-canary.yaml 2>/dev/null

# 7.4.3 블루그린 Rollout 삭제
kubectl delete -f $HOME/_Book_k8sInfra/ch7/7.4.3/ro-bluegreen.yaml 2>/dev/null

# 7.4.3 Argo Rollouts 삭제
kubectl delete namespace argo-rollouts 2>/dev/null

# 7.4.1 ArgoCD 삭제
kubectl delete namespace argocd 2>/dev/null

echo "✅ 7.4 cleanup done."
