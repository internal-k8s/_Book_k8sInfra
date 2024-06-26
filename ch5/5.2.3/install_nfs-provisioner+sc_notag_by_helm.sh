#!/usr/bin/env bash

helm install nfs-provisioner edu/nfs-subdir-external-provisioner \
--namespace nfs-provisioner \
--create-namespace \
--set nfs.server='192.168.1.10' \
--set nfs.path='/nfs_shared/dynamic-vol' \
--set storageClass.name='managed-nfs-storage' \
--set storageClass.pathPattern='${.PVC.namespace}-${.PVC.name}' \
--set storageClass.provisionerName='k8s-sigs.io/nfs-subdir-external-provisioner' \
--set fullnameOverride="nfs-client-provisioner" \
--set storageClass.onDelete='delete'

