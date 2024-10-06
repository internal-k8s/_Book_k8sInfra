#!/usr/bin/env bash

echo "> 커스텀 리소스 데피니션(customresourcedefinition) 배포"
kubectl create -f ~/_Book_k8sInfra/app/D.Operator/0.vagrant/extra-k8s-packages/elasticsearch/elastic-operator-config/crds.yaml
echo "> 엘라스틱서치 오퍼레이터(elastic-operator) 배포"
kubectl create -f ~/_Book_k8sInfra/app/D.Operator/0.vagrant/extra-k8s-packages/elasticsearch/elastic-operator-config/operator.yaml
echo "> 로그 적재를 위한 엘라스틱서치(elasticsearch) 커스텀 리소스 배포"
kubectl create -f ~/_Book_k8sInfra/app/D.Operator/0.vagrant/extra-k8s-packages/elasticsearch/elasticsearch.yaml
echo "> 엘라스틱서치에 적재된 로그를 시각화하기 위한 키바나(kibana) 커스텀 리소스 배포"
kubectl create -f ~/_Book_k8sInfra/app/D.Operator/0.vagrant/extra-k8s-packages/elasticsearch/kibana.yaml
echo "> 엘라스틱서치에 로그를 전송하기 위한 파일비트(filebeat) 커스텀 리소스 배포"
kubectl create -f ~/_Book_k8sInfra/app/D.Operator/0.vagrant/extra-k8s-packages/elasticsearch/filebeat.yaml
