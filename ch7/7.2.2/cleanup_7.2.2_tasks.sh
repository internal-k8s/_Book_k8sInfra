#!/usr/bin/env bash

HUBBLE_SVC="$(kubectl -n kube-system get svc hubble-ui)"

echo "First, check hubble-ui service."

if [ "$HUBBLE_SVC" != "" ]; then
  echo "Found hubble-ui service."
  echo "Check service type need to change action."
  SERVICE_TYPE="$(kubectl -n kube-system get svc hubble-ui -o jsonpath='{.spec.type}' | tr '[:upper:]' '[:lower:]')"
  if [ "$SERVICE_TYPE" == "loadbalancer" ]; then
    kubectl patch  -n kube-system svc/hubble-ui -p '{"spec":{"type":"ClusterIP"}}'
    echo "Hubble ui change type $SERVICE_TYPE to ClusterIP."
  else
     echo "Hubble ui already set ClusterIP."
  fi
  echo "Please take a look below details connection information."
  kubectl -n kube-system get svc hubble-ui
else
  echo "Cannot found hubble-ui service."
  echo "Please check is active cilium cni on this kubernetes cluster."
  echo "You may check 'kubectl get pods -n kube-system | grep cilium' command."
fi

echo "Second, delete the pods for cleanup and move forward to next task."
kubectl delete -f net-conn-pods.yaml
echo "Delete the pod."

echo "Check the pod is deleted."
kubectl get pods -o wide

echo "Let's move forward to next task."
