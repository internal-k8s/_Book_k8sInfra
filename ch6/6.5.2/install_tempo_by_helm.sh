
#!/usr/bin/env bash

helm install tempo edu/tempo \
--namespace monitoring \
--create-namespace \
--set persistence.enabled=true \
--set persistence.storageClassName="managed-nfs-storage" \
--set nodeSelector."kubernetes\.io/hostname"=cp-k8s \
--set securityContext.runAsNonRoot=false \
--set tolerations[0].key=node-role.kubernetes.io/control-plane \
--set tolerations[0].effect=NoSchedule \
--set tolerations[0].operator=Exists
