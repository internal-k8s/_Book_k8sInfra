#!/usr/bin/env bash


echo "===================================================="
echo "현재 엘라스틱서치 커스텀 리소스 상태"
kubectl get elasticsearch elasticsearch -n elastic-system
echo "===================================================="
echo "현재 엘라스틱서치 스테이트풀셋 상태"
kubectl get statefulset -l elasticsearch.k8s.elastic.co/cluster-name=elasticsearch -n elastic-system
echo "===================================================="
echo "현재 엘라스틱서치 파드 상태"
kubectl get pods -l elasticsearch.k8s.elastic.co/cluster-name=elasticsearch -n elastic-system
echo "===================================================="
echo "결함 주입: 스테이트풀셋 삭제"
kubectl delete statefulset -l elasticsearch.k8s.elastic.co/cluster-name=elasticsearch -n elastic-system
sleep 10
echo "===================================================="
echo "현재 엘라스틱서치 커스텀 리소스 상태"
kubectl get elasticsearch elasticsearch -n elastic-system
echo "===================================================="
echo "현재 엘라스틱서치 스테이트풀셋 상태"
kubectl get statefulset -l elasticsearch.k8s.elastic.co/cluster-name=elasticsearch -n elastic-system
echo "===================================================="
echo "현재 가용 가능한 엘라스틱서치 퍼시스턴스볼륨클레임"
kubectl get pvc -l elasticsearch.k8s.elastic.co/cluster-name=elasticsearch -n elastic-system
echo "===================================================="
echo "현재 엘라스틱서치 파드 상태"
kubectl get pods -l elasticsearch.k8s.elastic.co/cluster-name=elasticsearch -n elastic-system
echo "엘라스틱서치가 사용 가능할 때 까지 대기"
while [[ $(kubectl get elasticsearch elasticsearch -n elastic-system -o jsonpath='{.status.phase}') != "Ready" ]]; do
  echo "Waiting for Elasticsearch to be in Ready phase..."
  sleep 10
done
echo "Elasticsearch is now Ready."
kubectl get pods -l elasticsearch.k8s.elastic.co/cluster-name=elasticsearch -n elastic-system
echo "===================================================="
