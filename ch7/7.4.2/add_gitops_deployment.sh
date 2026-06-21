#!/usr/bin/env bash

REPO=~/gitops
SRC=~/_Book_k8sInfra/ch5/5.5.1
MSG="${1:-init commit}"

echo "Copy manifests from $SRC into ~/gitops."
cp "$SRC"/*.yaml "$REPO"/
ls "$REPO"

git -C "$REPO" add .
git -C "$REPO" commit -m "$MSG"
git -C "$REPO" push
