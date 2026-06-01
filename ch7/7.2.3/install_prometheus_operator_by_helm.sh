#!/usr/bin/env bash

echo "Configure control plane metrics to bind on all interfaces."
sed s,"- --bind-address=127.0.0.1","- --bind-address=0.0.0.0",g \
    -i /etc/kubernetes/manifests/kube-controller-manager.yaml
sed s,"- --bind-address=127.0.0.1","- --bind-address=0.0.0.0",g \
    -i /etc/kubernetes/manifests/kube-scheduler.yaml
sed s,"- --listen-metrics-urls=http://127.0.0.1:2381","- --listen-metrics-urls=http://0.0.0.0:2381",g \
    -i /etc/kubernetes/manifests/etcd.yaml

echo "Wait for control plane to roll out..."; sleep 5
while [ -z "$(crictl ps | grep etcd | grep Running)" ]
do
  echo "Control plane rollout in progress..."
  sleep 3
done
echo "Control plane rolled out successfully!"
echo ""

echo "Deploy prometheus-stack to monitoring namespace."
helm install prometheus-stack edu/kube-prometheus-stack \
  --namespace=monitoring \
  --create-namespace \
  -f $HOME/_Book_k8sInfra/ch7/7.2.3/prometheus-operator-values.yaml

echo ""
echo "Prometheus available at http://$(kubectl get svc -n monitoring -l app=kube-prometheus-stack-prometheus -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')"
echo "Grafana    available at http://$(kubectl get svc -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')"
