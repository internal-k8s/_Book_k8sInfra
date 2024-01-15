#!/usr/bin/env bash
KUBERNETES_VERSION=1.28.5
REGION=$(aws configure get region)
ZONE="${REGION}a"
CNI="calico"
CP_TYPE="t3.medium"
NODE_TYPE="t3.small"
NODE_COUNT=3

kops create cluster --kubernetes-version=1.28.5 \
  --zones=$ZONE \
  --networking=$CNI \
  --control-plane-size=$CP_TYPE \
  --node-size=$NODE_TYPE \
  --node-count=$NODE_COUNT \
  --name=$NAME \
  --yes
