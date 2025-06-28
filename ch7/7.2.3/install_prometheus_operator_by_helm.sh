#!/usr/bin/env bash

echo "First, enable expose control plane metrics for prometheus scrape control plane metrics."
echo "In this environment, cilium not using kube-proxy. they process eBPF/XDP."
echo "therefore you can't see kube-proxy metrics."

# bind-address for kube-controller-manager's metrics
echo "Configure metrics-binder for kube-controller-manager"
sed s,"- --bind-address=127.0.0.1","- --bind-address=0.0.0.0",g \
    -i /etc/kubernetes/manifests/kube-controller-manager.yaml
# bind-address for kube-scheduler's metrics
echo "Configure metrics-binder for kube-scheduler"
sed s,"- --bind-address=127.0.0.1","- --bind-address=0.0.0.0",g \
    -i /etc/kubernetes/manifests/kube-scheduler.yaml
# bind-address for etcd's metrics
echo "Configure metrics-binder for etcd"
sed s,"- --listen-metrics-urls=http://127.0.0.1:2381","- --listen-metrics-urls=http://0.0.0.0:2381",g \
    -i /etc/kubernetes/manifests/etcd.yaml
echo "===================================================="
echo "Wait for rolling out the control plane in few Seconds"; sleep 5
while [ -z "$(crictl ps | grep etcd | grep Running)" ]
do
  echo "control plane is rolling out in progress..."
  sleep 3
done
  echo "control plane rolled out successfully!"
echo "===================================================="

echo "Seconds, deploy grafana, prometheus, kube-state-metrics, node-exporter via helm."
helm install prometheus-stack edu/kube-prometheus-stack  \
--namespace=monitoring \
--create-namespace \
-f $HOME/_Book_k8sInfra/ch7/7.2.3/prometheus-operator-values.yaml

echo "===================================================="
echo "Prometheus available at http://$(kubectl get svc -n monitoring -l app=kube-prometheus-stack-prometheus -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')"
echo "Grafana available at http://$(kubectl get svc -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')"
echo "===================================================="

echo "Let's check the prometheus operator."
