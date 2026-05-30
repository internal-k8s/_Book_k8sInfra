#!/usr/bin/env bash

echo "🧹 [7.3] OpenTelemetry 실습 리소스 정리"

# 7.3.3 Tempo helm 삭제
helm uninstall tempo --namespace monitoring 2>/dev/null

# 7.3.2 / 7.3.3 OTel Collector 삭제
kubectl delete deployment otel-collector -n monitoring 2>/dev/null
kubectl delete service otel-collector -n monitoring 2>/dev/null
kubectl delete configmap otel-collector-config -n monitoring 2>/dev/null

# 7.3.1 Jaeger 삭제
kubectl delete deployment jaeger -n monitoring 2>/dev/null
kubectl delete service jaeger -n monitoring 2>/dev/null

# 7.3.1 HotROD 삭제
kubectl delete deployment hotrod 2>/dev/null
kubectl delete service hotrod 2>/dev/null

# monitoring 네임스페이스에 남은 리소스가 없으면 삭제
REMAINING="$(kubectl get all -n monitoring 2>/dev/null | grep -v '^NAME' | grep -v '^$')"
if [ -z "$REMAINING" ]; then
  kubectl delete namespace monitoring 2>/dev/null
  echo "   monitoring 네임스페이스 삭제 완료"
else
  echo "   ⚠️  monitoring 네임스페이스에 남은 리소스가 있습니다:"
  echo "$REMAINING"
fi

echo "✅ 7.3 cleanup done."
