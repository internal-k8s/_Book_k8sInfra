#!/bin/bash

# 커스텀 리소스 데피니션 배포
kubectl create -f elastic-operator-config/crds.yaml
# 엘라스틱서치 오퍼레이터 배포
kubectl create -f elastic-operator-config/operator.yaml
