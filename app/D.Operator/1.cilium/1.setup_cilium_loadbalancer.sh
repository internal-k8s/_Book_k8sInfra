#!/usr/bin/env bash

echo "> 실리움 로드밸런서 기능 활성화 시작"

echo "> 배포 전 로드밸런서 IP 주소 영역 확인 "
cat ~/_Book_k8sInfra/app/D.Operator/1.cilium/cilium-lb-config/cilium-loadbalancer-ip-pool.yaml | yq .spec
echo "> 로드밸런서 IP 주소 영역 설정"
kubectl apply -f ~/_Book_k8sInfra/app/D.Operator/1.cilium/cilium-lb-config/cilium-loadbalancer-ip-pool.yaml
echo "> 배포 후 로드밸런서 IP 주소 영역 확인 "
kubectl get ciliumloadbalancerippools.cilium.io lb-address-pool -o yaml | yq .spec

echo "> 배포 전 로드밸런서 IP 주소 영역 확인 "
cat ~/_Book_k8sInfra/app/D.Operator/1.cilium/cilium-lb-config/cilium-l2announcement-policy.yaml | yq .spec
echo "> 로드밸런서 IP 주소 영역 설정"
kubectl apply -f ~/_Book_k8sInfra/app/D.Operator/1.cilium/cilium-lb-config/cilium-l2announcement-policy.yaml
echo "> 배포 후 로드밸런서 IP 주소 영역 확인 "
kubectl get ciliuml2announcementpolicies.cilium.io l2-loadbalancer-announce-policy -o yaml | yq .spec


echo "> 실리움 로드밸런서 기능 활성화 완료"
