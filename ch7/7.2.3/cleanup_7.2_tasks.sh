#!/usr/bin/env bash

echo "🧹 [7.2] 실리움 / 프로메테우스 실습 리소스 정리"

# 7.2.2 hubble-ui 서비스 타입 복원 (LoadBalancer → ClusterIP)
HUI_TYPE="$(kubectl -n kube-system get svc hubble-ui -o jsonpath='{.spec.type}' 2>/dev/null | tr '[:upper:]' '[:lower:]')"
if [ "$HUI_TYPE" = "loadbalancer" ]; then
  kubectl patch -n kube-system svc/hubble-ui -p '{"spec":{"type":"ClusterIP"}}' 2>/dev/null
  echo "   hubble-ui: LoadBalancer → ClusterIP 복원"
fi

# 7.2.2 네트워크 테스트 파드 / CiliumNetworkPolicy
kubectl delete pod net-conn-allow net-conn-console net-conn-deny 2>/dev/null
kubectl delete ciliumnetworkpolicies.cilium.io cnp-allow-icmp-ping 2>/dev/null

# 7.2.3 컨트롤 플레인 메트릭 bind-address 복원 (CP 노드에서만 유효)
if [ -f /etc/kubernetes/manifests/kube-controller-manager.yaml ]; then
  sed -i s,"- --bind-address=0.0.0.0","- --bind-address=127.0.0.1",g \
      /etc/kubernetes/manifests/kube-controller-manager.yaml
  sed -i s,"- --bind-address=0.0.0.0","- --bind-address=127.0.0.1",g \
      /etc/kubernetes/manifests/kube-scheduler.yaml
  sed -i s,"- --listen-metrics-urls=http://0.0.0.0:2381","- --listen-metrics-urls=http://127.0.0.1:2381",g \
      /etc/kubernetes/manifests/etcd.yaml
  echo "   컨트롤 플레인 메트릭 bind-address 복원 (재시작 대기 중...)"
  sleep 5
  while [ -z "$(crictl ps 2>/dev/null | grep etcd | grep Running)" ]; do
    echo "   컨트롤 플레인 재시작 중..."
    sleep 3
  done
  echo "   컨트롤 플레인 재시작 완료"
else
  echo "   ⚠️  CP 노드가 아닙니다. CP 노드에서 별도로 bind-address를 복원하세요."
fi

# 7.2.3 prometheus-stack helm 삭제
helm uninstall prometheus-stack --namespace monitoring --no-hooks 2>/dev/null

# monitoring 네임스페이스 삭제
kubectl delete namespace monitoring 2>/dev/null

echo "✅ 7.2 cleanup done."
