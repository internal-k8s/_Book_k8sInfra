#!/usr/bin/env bash

echo "Configure Prometheus HA with replicas=2."
helm upgrade prometheus-stack edu/kube-prometheus-stack \
  --namespace=monitoring \
  -f $HOME/_Book_k8sInfra/ch7/7.2.3/prometheus-operator-values.yaml \
  --set prometheus.prometheusSpec.replicas=2
