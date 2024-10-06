#!/usr/bin/env bash


KB_ENDPOINT="http://$(kubectl get svc kibana-kb-http -n elastic-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
KB_PASSWORD="$(kubectl get secret elasticsearch-es-elastic-user -n elastic-system -o jsonpath='{ .data.elastic }' | base64 -d)"

echo -e "> 키바나 접속 엔드포인트: $KB_ENDPOINT\n> 키바나 접속 계정: elastic\n> 키바나 접속 패스워드: $KB_PASSWORD"
