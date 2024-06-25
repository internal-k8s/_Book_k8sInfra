#!/usr/bin/env bash

helm install nfs-client-provisioner edu/nfs-subdir-external-provisioner \
--namespace nfs-provisioner \
--create-namespace \
--set nfs.server='192.168.1.10' \
--set nfs.path='/nfs_shared/dynamic-vol' \
--set storageClass.name='managed-nfs-storage' \
--set storageClass.pathPattern='${.PVC.namespace}-${.PVC.name}' \
--set storageClass.provisionerName='k8s-sigs.io/nfs-subdir-external-provisioner' \
--set storageClass.onDelete='delete' \
--set image.tag='v4.0.2'

