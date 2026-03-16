#!/usr/bin/env bash

echo "🚀 Deploy OTel Collector to monitoring namespace."
kubectl apply -f $HOME/_Book_k8sInfra/ch7/7.3.2/otel-collector.yaml

echo "⏳ Wait for OTel Collector to be ready..."
kubectl wait --for=condition=available deployment/otel-collector -n monitoring --timeout=120s

echo "🔄 Switch HotROD app to use Collector (instead of direct Jaeger connection)."
kubectl apply -f $HOME/_Book_k8sInfra/ch7/7.3.2/hotrod-with-collector.yaml

echo "⏳ Wait for HotROD to be updated..."
kubectl wait --for=condition=available deployment/hotrod --timeout=120s

echo ""
echo "✅ OTel Collector deployed."
echo ""
echo "📌 파이프라인 구성:"
echo "   HotROD (앱) → OTel Collector → Jaeger"
echo ""
echo "📌 변경된 점:"
echo "   Before: OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger.monitoring:4318"
echo "   After:  OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector.monitoring:4318"
echo ""
echo "📌 앱은 Collector 주소만 알면 됩니다. 백엔드 교체는 Collector에서 처리."
