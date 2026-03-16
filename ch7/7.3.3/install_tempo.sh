#!/usr/bin/env bash

echo "🚀 Deploy Tempo to monitoring namespace."
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null
helm repo update grafana

helm upgrade --install tempo grafana/tempo \
  --namespace monitoring \
  -f $HOME/_Book_k8sInfra/ch7/7.3.3/tempo-values.yaml

echo "⏳ Wait for Tempo to be ready..."
kubectl wait --for=condition=available deployment/tempo -n monitoring --timeout=180s

echo ""
echo "✅ Tempo deployed in monitoring namespace."
echo "📌 OTLP endpoint: tempo.monitoring.svc.cluster.local:4317"
