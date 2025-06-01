#!/usr/bin/env bash
echo "[Step 1/3] Uninstalling Load-generator..."
helm uninstall  load-generator edu/load-generator \
--namespace colosseum \
--create-namespace > /dev/null 2>&1

echo "[Step 2/3] Uninstalling Colosseum apps..."
helm uninstall colosseum edu/colosseum \
--namespace colosseum \
--create-namespace \
--set monitoring.mode=trace

echo "[Step 3/3] Uninstalling Redis..."
helm uninstall redis edu/redis \
--namespace colosseum \
--create-namespace > /dev/null 2>&1

echo "Remove colosseum namespace."
kubectl delete namespace colosseum
