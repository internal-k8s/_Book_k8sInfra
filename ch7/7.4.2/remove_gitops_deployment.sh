#!/usr/bin/env bash

REPO=~/gitops
MSG="${1:-del gitops-nginx deployment}"

echo "Remove deployment.yaml from ~/gitops."
rm "$REPO/deployment.yaml"
ls "$REPO"

git -C "$REPO" add .
git -C "$REPO" commit -m "$MSG"
git -C "$REPO" push
