#!/usr/bin/env bash

echo "First, check hubble-ui service."
echo "hubble-ui is already exposed as LoadBalancer (provisioned at 7.1.1 vagrant up)."
echo "Please take a look below details connection information."
kubectl -n kube-system get svc hubble-ui

echo "Second, prepare the pods for check cilium network connectivity and network policy."
kubectl apply -f ~/_Book_k8sInfra/ch7/7.2.2/net-conn-pods.yaml
echo "Create the pod."

echo "Check the pod is running."
kubectl get pods -o wide

echo "Yon can go to next step, journey to cilium and hubble ui."
echo "The hubble ui is available at http://$(kubectl -n kube-system get svc hubble-ui -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"

echo "You can check the network connectivity and network policy."
echo "Let's check the network connectivity."

