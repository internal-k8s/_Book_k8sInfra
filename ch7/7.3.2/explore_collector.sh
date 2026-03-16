#!/usr/bin/env bash

echo "=============================================="
echo " 7.3.2 OTel Collector 파이프라인 확인"
echo "=============================================="

echo ""
echo "📋 Collector 설정 확인:"
echo "----------------------------------------------"
kubectl get configmap otel-collector-config -n monitoring -o jsonpath='{.data.config\.yaml}'
echo ""

echo ""
echo "----------------------------------------------"
echo "📊 Collector 파이프라인 구조:"
echo "----------------------------------------------"
echo "  receivers:   [otlp]          ← 앱에서 OTLP로 트레이스 수신"
echo "  processors:  [batch, attributes] ← 배치 처리 + 환경 태그 추가"
echo "  exporters:   [otlp/jaeger, debug] ← Jaeger로 전송 + 디버그 로그"
echo ""

echo "----------------------------------------------"
echo "📋 HotROD 앱의 OTel 환경변수 확인:"
echo "----------------------------------------------"
kubectl get deploy hotrod -o jsonpath='{range .spec.template.spec.containers[0].env[*]}{.name}={.value}{"\n"}{end}'
echo ""

echo "----------------------------------------------"
echo "📋 Collector 로그에서 트레이스 수신 확인:"
echo "----------------------------------------------"
kubectl logs deployment/otel-collector -n monitoring --tail=10

echo ""
echo "💡 HotROD에서 트래픽을 발생시킨 후 Jaeger UI에서 동일한 트레이스를 확인하세요."
echo "💡 Collector의 debug exporter가 로그에 트레이스 정보를 출력합니다."
