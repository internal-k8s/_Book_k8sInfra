#!/usr/bin/env bash

echo "Free resources from 7.1 to 7.4 before deploying sLLM."

CH7="$HOME/_Book_k8sInfra/ch7"
bash "$CH7/7.1.3/cleanup_7.1_tasks.sh"
bash "$CH7/7.2.3/cleanup_7.2_tasks.sh"
bash "$CH7/7.3.3/cleanup_7.3_tasks.sh"
bash "$CH7/7.4.3/cleanup_7.4_tasks.sh"

# Revert control-plane bind-address exposed in 7.2 for Prometheus scraping.
if [ -f /etc/kubernetes/manifests/kube-controller-manager.yaml ]; then
  sed s,"- --bind-address=0.0.0.0","- --bind-address=127.0.0.1",g \
      -i /etc/kubernetes/manifests/kube-controller-manager.yaml
  sed s,"- --bind-address=0.0.0.0","- --bind-address=127.0.0.1",g \
      -i /etc/kubernetes/manifests/kube-scheduler.yaml
  sed s,"- --listen-metrics-urls=http://0.0.0.0:2381","- --listen-metrics-urls=http://127.0.0.1:2381",g \
      -i /etc/kubernetes/manifests/etcd.yaml
  echo "Waiting for control plane to roll out..."; sleep 5
  while [ -z "$(crictl ps | grep etcd | grep Running)" ] 2>/dev/null; do
    echo "Control plane rollout in progress..."
    sleep 3
  done
fi

echo "7.1 to 7.4 cleanup done."
