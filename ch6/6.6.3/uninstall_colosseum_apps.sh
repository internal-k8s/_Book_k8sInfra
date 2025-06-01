#!/usr/bin/env bash
echo "[Step 1/4] Uninstalling Load-generator..."
helm uninstall  load-generator \
--namespace colosseum > /dev/null 2>&1

echo "[Step 2/4] Uninstalling Colosseum apps..."
helm uninstall colosseum \
--namespace colosseum 

echo "[Step 3/4] Uninstalling Redis..."
helm uninstall redis \
--namespace colosseum > /dev/null 2>&1

echo "[Step 4/4] Deleting colosseum namespace..."
kubectl delete namespace colosseum
