#!/usr/bin/env bash

echo "🚀 Deploy Jaeger all-in-one to monitoring namespace."
kubectl apply -f $HOME/_Book_k8sInfra/ch7/7.3.1/jaeger-all-in-one.yaml

echo "⏳ Wait for Jaeger to be ready..."
kubectl wait --for=condition=available deployment/jaeger -n monitoring --timeout=120s

echo "🚀 Deploy HotROD demo app (direct connection to Jaeger)."
kubectl apply -f $HOME/_Book_k8sInfra/ch7/7.3.1/hotrod-direct.yaml

echo "⏳ Wait for HotROD to be ready..."
kubectl wait --for=condition=available deployment/hotrod --timeout=120s

JAEGER_IP="$(kubectl get svc jaeger -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
HOTROD_IP="$(kubectl get svc hotrod -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"

echo ""
echo "✅ Jaeger UI: http://$JAEGER_IP:16686"
echo "✅ HotROD UI: http://$HOTROD_IP"
echo ""
echo "📌 HotROD에서 'Request Ride' 버튼을 클릭하면 트레이스가 생성됩니다."
echo "📌 Jaeger UI에서 Service 'frontend'를 선택하면 트레이스를 확인할 수 있습니다."
