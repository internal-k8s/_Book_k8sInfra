#!/usr/bin/env bash

echo "Deploy OTel Collector to monitoring namespace."
kubectl apply -f $HOME/_Book_k8sInfra/ch7/7.3.2/otel-collector.yaml

echo "Wait for OTel Collector to be ready..."
kubectl wait --for=condition=available deployment/otel-collector -n monitoring --timeout=120s

echo "Switch HotROD to send traces to OTel Collector."
kubectl apply -f $HOME/_Book_k8sInfra/ch7/7.3.2/hotrod-with-collector.yaml

echo "Wait for HotROD to be ready..."
kubectl wait --for=condition=available deployment/hotrod --timeout=120s

echo ""
echo "OTel Collector deployed."
echo "Pipeline: HotROD -> OTel Collector -> Jaeger"
