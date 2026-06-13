#!/usr/bin/env bash

kubectl get namespace monitoring &>/dev/null || kubectl create namespace monitoring

echo "Deploy OTel Collector to monitoring namespace."
kubectl apply -f $HOME/_Book_k8sInfra/ch7/7.3.2/otel-collector.yaml

echo "Wait for OTel Collector to be ready..."
kubectl rollout status deployment/otel-collector -n monitoring --timeout=120s

echo ""
echo "OTel Collector deployed."

