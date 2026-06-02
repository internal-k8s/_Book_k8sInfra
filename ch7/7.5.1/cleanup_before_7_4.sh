#!/usr/bin/env bash

echo "Remove 7.1 to 7.4 resources."

kubectl delete rollout canary-nginx 2>/dev/null
kubectl delete svc canary-nginx 2>/dev/null

kubectl delete rollout bluegreen-nginx 2>/dev/null
kubectl delete svc bluegreen-active bluegreen-preview 2>/dev/null

kubectl delete namespace argo-rollouts 2>/dev/null

kubectl delete namespace argocd 2>/dev/null

kubectl delete deploy hotrod 2>/dev/null
kubectl delete svc hotrod 2>/dev/null
kubectl delete deploy jaeger -n monitoring 2>/dev/null
kubectl delete svc jaeger -n monitoring 2>/dev/null
kubectl delete deploy otel-collector -n monitoring 2>/dev/null
kubectl delete svc otel-collector -n monitoring 2>/dev/null
kubectl delete configmap otel-collector-config -n monitoring 2>/dev/null
helm uninstall grafana-stack --namespace monitoring 2>/dev/null

helm uninstall prometheus-stack --namespace monitoring --no-hooks 2>/dev/null

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

kubectl delete pod net-conn-allow 2>/dev/null
kubectl delete pod net-conn-console 2>/dev/null
kubectl delete pod net-conn-deny 2>/dev/null
kubectl delete ciliumnetworkpolicies.cilium.io cnp-allow-icmp-ping 2>/dev/null

kubectl delete deployment nginx-by-k8s-dash 2>/dev/null
kubectl delete deployment nginx-by-headlamp 2>/dev/null
kubectl delete -f $HOME/_Book_k8sInfra/ch7/7.1.2/kubernetes-dashboard.yaml 2>/dev/null

REMAINING="$(kubectl get all -n monitoring 2>/dev/null | grep -v 'No resources')"
if [ -n "$REMAINING" ]; then
  echo "Resources remaining in monitoring namespace:"
  echo "$REMAINING"
else
  kubectl delete namespace monitoring 2>/dev/null
fi

echo "7.1 to 7.4 cleanup done."
