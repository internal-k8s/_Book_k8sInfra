#!/usr/bin/env bash

echo "🧹 Clean up 7.4.3 Canary Rollout resources."

kubectl delete rollout canary-nginx 2>/dev/null
kubectl delete svc canary-nginx 2>/dev/null

echo "✅ 7.4.3 cleanup done."
