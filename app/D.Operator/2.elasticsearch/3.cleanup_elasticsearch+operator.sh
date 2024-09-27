#!/usr/bin/env bash

echo "> 로그 적재를 위한 엘라스틱서치(elasitcsearch) 클러스터 삭제"
kubectl delete -f ~/_Book_k8sInfra/app/D.Operator/2.elasticsearch/elasticsearch.yaml
echo "> 엘라스틱서치에 적재된 로그를 시각화하기 위한 키바나(kibana) 삭제"
kubectl delete -f ~/_Book_k8sInfra/app/D.Operator/2.elasticsearch/kibana.yaml
echo "> 엘라스틱서치에 로그를 전송하기 위한 파일비트(filebeat) 삭제"
kubectl delete -f ~/_Book_k8sInfra/app/D.Operator/2.elasticsearch/filebeat.yaml
echo "> 엘라스틱서치 오퍼레이터(elastic-operator) 삭제"
kubectl delete -f ~/_Book_k8sInfra/app/D.Operator/2.elasticsearch/elastic-operator-config/operator.yaml
echo "> 커스텀 리소스 데피니션(customresourcedefinition) 삭제"
kubectl delete -f ~/_Book_k8sInfra/app/D.Operator/2.elasticsearch/elastic-operator-config/crds.yaml
