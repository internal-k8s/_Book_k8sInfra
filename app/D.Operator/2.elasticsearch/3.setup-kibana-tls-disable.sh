#!/usr/bin/env bash


echo "===================================================="
echo "현재 키바나 커스텀 리소스 상태"
kubectl get kibana kibana
echo "===================================================="
echo "현재 키바나 파드 상태"
kubectl get pods -l kibana.k8s.elastic.co/name=kibana
echo "===================================================="
echo "키바나 HTTP 설정 변경 사항 확인"
diff kibana.yaml kibana_tls_disable.yaml
echo "키바나 TLS 설정 변경 적용"
kubectl apply -f kibana_tls_disable.yaml
echo "===================================================="
echo "현재 키바나 커스텀 리소스 상태"
kubectl get kibana kibana
echo "===================================================="
echo "현재 키바나 파드 상태"
kubectl get pods -l kibana.k8s.elastic.co/name=kibana
echo "===================================================="
echo "새로 배포되는 키바나가 준비될 때까지 대기"
kubectl wait --for=condition=ready pod -l kibana.k8s.elastic.co/name=kibana --timeout=300s
echo "===================================================="
echo "현재 키바나 파드 상태"
kubectl get pods -l kibana.k8s.elastic.co/name=kibana
echo "===================================================="
