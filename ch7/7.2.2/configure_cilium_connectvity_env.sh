#!/usr/bin/env bash

HUBBLE_SVC="$(kubectl -n kube-system get svc hubble-ui)"

echo "First, check hubble-ui service."

if [ "$HUBBLE_SVC" != "" ]; then
  echo "Found hubble-ui service."
  echo "Check service type need to change action."
  SERVICE_TYPE="$(kubectl -n kube-system get svc hubble-ui -o jsonpath='{.spec.type}' | tr '[:upper:]' '[:lower:]')"
  if [ "$SERVICE_TYPE" != "loadbalancer" ]; then
    kubectl patch  -n kube-system svc/hubble-ui -p '{"spec":{"type":"LoadBalancer"}}'
    echo "Hubble ui change type $SERVICE_TYPE to Loadbalancer."
  else
     echo "Hubble ui already set Loadbalancer."
  fi
  echo "Please take a look below details connection information."
  kubectl -n kube-system get svc hubble-ui
else
  echo "Cannot found hubble-ui service."
  echo "Please check is active cilium cni on this kubernetes cluster."
  echo "You may check 'kubectl get pods -n kube-system | grep cilium' command."
fi

echo "Second, prepare the pods for check cilium network connectivity and network policy."
kubectl apply -f net-conn-pods.yaml
echo "Create the pod."

echo "Check the pod is running."
kubectl get pods -o wide

echo "Yon can go to next step, journey to cilium and hubble ui."
echo "The hubble ui is available at http://$(kubectl -n kube-system get svc hubble-ui -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"

echo "You can check the network connectivity and network policy."
echo "Let's check the network connectivity."

