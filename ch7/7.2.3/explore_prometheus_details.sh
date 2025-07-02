#!/usr/bin/env bash

echo "Let's explore the prometheus details."
STS_MANIFEST="$(kubectl get -n monitoring sts prometheus-prometheus-stack-kube-prom-prometheus -o yaml)"


echo "First, check the prometheus statefulset owner reference."
echo "$STS_MANIFEST" | yq -e '.metadata.ownerReferences'

echo "Second, check the statefulset volumes."
echo "$STS_MANIFEST" | yq -e '.spec.volumeClaimTemplates'

echo "Third, check the prometheus pod owner reference."
POD_MANIFEST="$(kubectl get po -n monitoring prometheus-prometheus-stack-kube-prom-prometheus-0 -o yaml)"
echo "$POD_MANIFEST" | yq -e '.metadata.ownerReferences'

echo "Fourth, check the prometheus pod volumes."
echo "$POD_MANIFEST" | yq -e '.spec.volumes[] | select(.persistentVolumeClaim != null)'

echo "Fifth, check the prometheus pvc is bound."
PVC_NAME=$(echo "$POD_MANIFEST" | yq -e '.spec.volumes[] | select(.persistentVolumeClaim != null) | .persistentVolumeClaim.claimName')
kubectl get pvc -n monitoring $PVC_NAME 


