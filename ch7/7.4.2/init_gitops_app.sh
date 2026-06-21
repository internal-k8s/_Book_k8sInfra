#!/usr/bin/env bash

REPO_URL="$(git -C ~/gitops remote get-url origin 2>/dev/null | sed 's/\.git$//')"
echo "Set repoURL: $REPO_URL"
yq e -i ".spec.source.repoURL = \"$REPO_URL\"" \
  $HOME/_Book_k8sInfra/ch7/7.4.2/app-gitops-nginx.yaml
