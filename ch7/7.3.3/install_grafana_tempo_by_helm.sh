#!/usr/bin/env bash

echo "Deploy Grafana and Tempo to monitoring namespace."
helm repo add k8s-edu https://k8s-edu.github.io/Bkv2_main/helm-charts/ 2>/dev/null
helm repo update k8s-edu

helm upgrade --install grafana-stack k8s-edu/grafana-stack \
  --namespace monitoring \
  --create-namespace \
  -f $HOME/_Book_k8sInfra/ch7/7.3.3/grafana-tempo-values.yaml

echo "Wait for Grafana to be ready..."
kubectl rollout status deployment/grafana-stack \
  -n monitoring --timeout=180s

echo "Wait for Tempo to be ready..."
kubectl rollout status statefulset/grafana-stack-tempo \
  -n monitoring --timeout=180s

GRAFANA_IP="$(kubectl get svc grafana-stack -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"

echo ""
echo "Grafana available at http://$GRAFANA_IP"
echo "Tempo OTLP endpoint: grafana-stack-tempo.monitoring.svc.cluster.local:4317"
