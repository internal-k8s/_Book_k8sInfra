#!/usr/bin/env bash

echo "Remove 7.4 resources."

kubectl delete rollout canary-nginx 2>/dev/null
kubectl delete service canary-nginx 2>/dev/null

kubectl delete rollout bluegreen-nginx 2>/dev/null
kubectl delete service bluegreen-active bluegreen-preview 2>/dev/null

kubectl delete namespace argo-rollouts 2>/dev/null

kubectl delete namespace argocd 2>/dev/null

echo "7.4 cleanup done."
