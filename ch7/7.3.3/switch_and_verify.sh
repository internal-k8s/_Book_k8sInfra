#!/usr/bin/env bash

echo "=============================================="
echo " 7.3.3 백엔드 교체: Jaeger → Tempo"
echo "=============================================="
echo ""
echo "📋 변경 전 Collector exporter:"
kubectl get configmap otel-collector-config -n monitoring -o jsonpath='{.data.config\.yaml}' | grep -A2 "exporters:"
echo ""

echo "🔄 Collector ConfigMap을 Tempo exporter로 교체합니다."
kubectl apply -f $HOME/_Book_k8sInfra/ch7/7.3.3/otel-collector-to-tempo.yaml

echo "🔄 Collector를 재시작하여 새 설정을 반영합니다."
kubectl rollout restart deployment/otel-collector -n monitoring
kubectl rollout status deployment/otel-collector -n monitoring --timeout=60s

echo ""
echo "📋 변경 후 Collector exporter:"
kubectl get configmap otel-collector-config -n monitoring -o jsonpath='{.data.config\.yaml}' | grep -A2 "exporters:"
echo ""

echo "----------------------------------------------"
echo "✅ 백엔드 교체 완료!"
echo "----------------------------------------------"
echo ""
echo "📌 핵심: 앱(HotROD)의 환경변수는 변경하지 않았습니다."
kubectl get deploy hotrod -o jsonpath='   OTEL_EXPORTER_OTLP_ENDPOINT={.spec.template.spec.containers[0].env[?(@.name=="OTEL_EXPORTER_OTLP_ENDPOINT")].value}'
echo ""
echo ""
echo "📌 파이프라인 변경:"
echo "   Before: HotROD → Collector → Jaeger"
echo "   After:  HotROD → Collector → Tempo"
echo ""

GRAFANA_IP="$(kubectl get svc -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')"
echo "📌 Grafana에서 Tempo 데이터소스를 추가하고 트레이스를 확인하세요."
echo "   Grafana: http://$GRAFANA_IP"
echo "   Tempo URL: http://tempo.monitoring:3100"
echo ""
echo "💡 이것이 OTel Collector의 핵심 가치입니다:"
echo "   앱 수정 없이 백엔드를 자유롭게 교체할 수 있습니다."
