#!/usr/bin/env bash

YAML="$HOME/_Book_k8sInfra/ch7/7.5.2/po-compare-sllm.yaml"

# Re-run cleanly: drop a previous test pod, then re-create.
kubectl delete -f "$YAML" 2>/dev/null
kubectl apply -f "$YAML"

echo "Wait for compare-sllm pod to be ready..."
kubectl wait pod/compare-sllm --for=condition=Ready --timeout=120s

# Stream results; logs -f ends when the test pod completes.
kubectl logs -f pod/compare-sllm
