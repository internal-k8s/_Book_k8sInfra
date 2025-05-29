#!/usr/bin/env bash
echo "Deploy redis."
helm upgrade --install redis edu/redis \
--namespace colosseum \
--create-namespace > /dev/null 2>&1

echo "Wait for redis is ready."
kubectl -n colosseum wait deployment/redis --for=condition=available

echo "Deploy colosseum apps."
helm upgrade --install colosseum edu/colosseum \
--namespace colosseum \
--create-namespace \
--set monitoring.mode=profile