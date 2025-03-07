
#!/usr/bin/env bash
helm install tempo edu/tempo \
--namespace monitoring \
--create-namespace \
--set persistence.enabled=true \
--set persistence.storageClassName="managed-nfs-storage"
