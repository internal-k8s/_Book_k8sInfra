#!/usr/bin/env bash

echo "🧹 Clean up 7.4.2 Blue-Green Rollout resources."

kubectl delete rollout bluegreen-nginx 2>/dev/null
kubectl delete svc bluegreen-active bluegreen-preview 2>/dev/null

echo "✅ 7.4.2 cleanup done."
