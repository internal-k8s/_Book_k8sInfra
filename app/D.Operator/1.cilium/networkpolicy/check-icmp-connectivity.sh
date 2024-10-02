#!/usr/bin/env bash

ALLOW_IP=$(kubectl get pods net-conn-allow -o jsonpath="{.status.podIP}")
DENY_IP=$(kubectl get po net-conn-deny -o jsonpath="{.status.podIP}")

echo "현재 배포된 pod 상태"
echo "=============================================="
kubectl get po -o wide --show-labels
echo "=============================================="

echo "> [console to allow] ping 3회 테스트"
kubectl exec net-conn-console -- ping -c 3 $ALLOW_IP

echo -e "\n\n"

echo "> [console to deny] ping 3회 테스트"
kubectl exec net-conn-console -- ping -c 3 $DENY_IP
