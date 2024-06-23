#!/usr/bin/env bash
kubectl delete -f ~/_Book_k8sInfra/ch3/3.4.3/ > /dev/null 2>&1 &
echo "Exist nfs-subdir-external-provisioner resources are removed"

