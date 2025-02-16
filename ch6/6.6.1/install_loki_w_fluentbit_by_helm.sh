#!/usr/bin/env bash
echo "[1/2] Install Log Storage Loki by Helm"
helm install loki edu/loki \
--namespace monitoring \
--create-namespace \
--set deploymentMode=SingleBinary \
--set loki.commonConfig.replication_factor=1 \
--set lokiCanary.enabled=false \
--set test.enabled=false \
--set loki.auth_enabled=false \
--set loki.storage.type=filesystem \
--set loki.schemaConfig.configs[0].from="2024-01-01" \
--set loki.schemaConfig.configs[0].store=tsdb \
--set loki.schemaConfig.configs[0].index.prefix=loki_index_ \
--set loki.schemaConfig.configs[0].index.period=24h \
--set loki.schemaConfig.configs[0].object_store=filesystem \
--set loki.schemaConfig.configs[0].schema=v13 \
--set gateway.nginxConfig.enableIPv6=false \
--set chunksCache.enabled=false \
--set resultsCache.enabled=false \
--set singleBinary.replicas=1 \
--set read.replicas=0 \
--set backend.replicas=0 \
--set write.replicas=0 \
--set singleBinary.persistence.enableStatefulSetAutoDeletePVC=false \
--set singleBinary.persistence.storageClass="managed-nfs-storage" 
echo "[2/2] Install log forwarder fluent-bit by Helm"
helm install fluent-bit edu/fluent-bit \
--namespace monitoring \
--create-namespace \
--set testFramework.enabled=false \
--set loki.host=loki-gateway.monitoring.svc.cluster.local \
--set tolerations[0].key=node-role.kubernetes.io/control-plane \
--set tolerations[0].effect=NoSchedule \
--set tolerations[0].operator=Exists    
