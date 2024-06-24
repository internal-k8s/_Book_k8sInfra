#!/usr/bin/env bash
helm install nfs-subdir-external-provisioner book-k8sinfra-v2/nfs-subdir-external-provisioner \
--namespace nfs-provisioner \
--create-namespace \
--set nfs.server='192.168.1.10' \
--set nfs.path='/nfs_shared/dynamic-vol' \
--set storageClass.name='managed-nfs-storage' \
--set storageClass.pathPattern='${.PVC.namespace}-${.PVC.name}' \
--set storageClass.accessModes='ReadWriteMany' \
--set storageClass.onDelete='delete'


