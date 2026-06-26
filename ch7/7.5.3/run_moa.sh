#!/usr/bin/env bash

YAML="$HOME/_Book_k8sInfra/ch7/7.5.3/po-moa.yaml"

# Re-run cleanly: drop previous MoA pods, then re-create.
kubectl delete -f "$YAML" 2>/dev/null
kubectl apply -f "$YAML"

echo "Wait for MoA pods to be ready..."
kubectl wait pod/moa-english pod/moa-korean --for=condition=Ready --timeout=120s

# Stream each pod's result in turn; logs -f ends when the pod completes.
echo ""
echo "================= moa-english ================="
kubectl logs -f pod/moa-english
echo ""
echo "================= moa-korean =================="
kubectl logs -f pod/moa-korean
