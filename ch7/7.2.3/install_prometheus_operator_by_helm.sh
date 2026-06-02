#!/usr/bin/env bash

echo "Deploy prometheus-stack to monitoring namespace."
helm install prometheus-stack edu/kube-prometheus-stack \
  --namespace=monitoring \
  --create-namespace \
  -f $HOME/_Book_k8sInfra/ch7/7.2.3/prometheus-operator-values.yaml

echo ""
echo "Prometheus available at http://$(kubectl get svc -n monitoring -l app=kube-prometheus-stack-prometheus -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')"
