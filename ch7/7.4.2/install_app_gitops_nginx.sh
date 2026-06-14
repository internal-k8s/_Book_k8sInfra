#!/usr/bin/env bash

if ! git -C ~/gitops remote get-url origin &>/dev/null; then
  echo "~/gitops not found or has no remote. Please complete Chapter 5 labs first."
  exit 1
fi

REPO_URL="$(git -C ~/gitops remote get-url origin | sed 's/\.git$//')"

echo "Deploy app-gitops-nginx with repoURL: $REPO_URL"
yq e ".spec.source.repoURL = \"$REPO_URL\"" \
  $HOME/_Book_k8sInfra/ch7/7.4.2/app-gitops-nginx.yaml | kubectl apply -f -
