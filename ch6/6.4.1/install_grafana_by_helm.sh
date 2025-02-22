#!/usr/bin/env bash
helm install grafana edu/grafana \
--namespace monitoring \
--create-namespace \
--set persistence.enabled=true \
--set persistence.storageClassName="managed-nfs-storage" \
--set service.type=LoadBalancer \
--set securityContext.runAsUser=1000 \
--set securityContext.runAsGroup=1000 \
--set "grafana\.ini".server.root_url="http://192.168.1.12" \
--set adminPassword="admin"
