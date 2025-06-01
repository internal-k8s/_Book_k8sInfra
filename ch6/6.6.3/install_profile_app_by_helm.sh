#!/usr/bin/env bash
echo "[Step 1/3] Deploying Redis..."
helm upgrade --install redis edu/redis \
--namespace colosseum \
--create-namespace > /dev/null 2>&1

kubectl -n colosseum wait deployment/redis --for=condition=available > /dev/null 2>&1
echo "Done"

echo "[Step 2/3] Deploying Colosseum apps..."
helm upgrade --install colosseum edu/colosseum \
--namespace colosseum \
--create-namespace \
--set monitoring.mode=profile

echo "[Step 3/3] Deploying Load-generator..."
helm upgrade --install  load-generator edu/load-generator \
--namespace colosseum \
--create-namespace > /dev/null 2>&1
