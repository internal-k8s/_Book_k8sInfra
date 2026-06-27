#!/usr/bin/env bash

YAML="$HOME/_Book_k8sInfra/ch7/7.5.3/po-moa.yaml"

# [Aggregator 선택] 기본은 소형 gemma3-270m (모든 노드에서 실행 가능).
# 12GB 워커라면 상위 모델로 바꿔 3개 응답을 검증·종합하는 효과를 재현할 수 있습니다.
#   AGG_SVC=ollama-gemma3-4b AGG_MODEL=gemma3:4b ./run_moa.sh
AGG_SVC="${AGG_SVC:-ollama-gemma3-270m}"
AGG_MODEL="${AGG_MODEL:-gemma3:270m}"

echo "Set aggregator: $AGG_SVC ($AGG_MODEL)"
yq e -i "with(select(.kind == \"Pod\").spec.containers[]; .args[1] = \"$AGG_SVC\" | .args[2] = \"$AGG_MODEL\")" "$YAML"

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
