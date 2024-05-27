#!/usr/bin/env bash
curl -L \
https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.4.1/kustomize_v5.4.1_linux_amd64.tar.gz -o /tmp/kustomize.tar.gz
tar -xzf /tmp/kustomize.tar.gz -C  /usr/local/bin
VERSION=$(kustomize version)
echo "kustomize $VERSION install successfully"
