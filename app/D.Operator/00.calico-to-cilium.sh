#!/usr/bin/env bash

# Lock: avoid side effect when change cni phase.
for i in $(seq 1 1 3)
do
  kubectl cordon w${i}-k8s
done

# CNI raw address & config for kubernetes's network 
CNI_ADDR="https://raw.githubusercontent.com/sysnet4admin/IaC/master/k8s/CNI"
kubectl delete -f $CNI_ADDR/172.16_net_calico_v3.26.0.yaml

# install cilium-cli and add permisssion to execute 
curl -L https://github.com/sysnet4admin/BB/raw/main/cilium-cli/v0.14.6/cilium \
     -o /usr/local/bin/cilium
chmod 744 /usr/local/bin/cilium 
# config for kubernetes's network by cilium 
cilium install \
  --version=v1.14.5 \
    --helm-set ipam.mode=kubernetes \
    --helm-set ipv4NativeRoutingCIDR="172.16.0.0/16" \
    --helm-set enable-l2-announcements="true" \
    --helm-set kubeProxyReplacement="true" \
    --helm-set externalIPs="true" \
    --helm-set hubble.enabled="true" \
    --helm-set hubble.relay.enabled="true" \
    --helm-set hubble.ui.enabled="true"

# UnLock: rollback cordon to node available.
for i in $(seq 1 1 3)
do
  kubectl uncordon w${i}-k8s
done
