#!/usr/bin/env bash

# wait for control-plane API server to be ready
until curl -sk https://192.168.1.10:6443/livez | grep -q "ok"; do
  echo "Waiting for API server..."; sleep 10
done

# config for worker nodes only
kubeadm join --token 123456.1234567890123456 \
             --discovery-token-unsafe-skip-ca-verification 192.168.1.10:6443
