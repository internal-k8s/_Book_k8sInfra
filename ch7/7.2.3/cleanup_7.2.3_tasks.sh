#!/usr/bin/env bash

echo "First, disable exposecontrol plane metrics."
# Cleanup metrics-binder for kube-controller-manager's metrics
echo "Cleanup metrics-binder for kube-controller-manager"
sed s,"- --bind-address=0.0.0.0","- --bind-address=127.0.0.1",g \
    -i /etc/kubernetes/manifests/kube-controller-manager.yaml
# Cleanup metrics-binder for kube-scheduler's metrics
echo "Cleanup metrics-binder for kube-scheduler"
sed s,"- --bind-address=0.0.0.0","- --bind-address=127.0.0.1",g \
    -i /etc/kubernetes/manifests/kube-scheduler.yaml
# Cleanup metrics-binder for etcd's metrics
echo "Cleanup metrics-binder for etcd"
sed s,"- --listen-metrics-urls=http://0.0.0.0:2381","- --listen-metrics-urls=http://127.0.0.1:2381",g \
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

echo "Seconds, cleanup prometheus-stack (including grafana, prometheus, kube-state-metrics, node-exporter) via helm."
helm uninstall prometheus-stack \
--namespace=monitoring \
--no-hooks

echo "===================================================="
echo "Prometheus-stack (including grafana, prometheus, kube-state-metrics, node-exporter) are now unavailable."
echo "===================================================="

echo "Let's move forward to next task."
