#!/usr/bin/env bash

echo "=============================================="
echo " 7.5 실습 전 리소스 정리"
echo " 7.1~7.4에서 배포한 리소스를 모두 삭제합니다."
echo "=============================================="
echo ""

# 7.4.3 카나리 Rollout
echo "🧹 [7.4.3] 카나리 Rollout 정리"
kubectl delete rollout canary-nginx 2>/dev/null
kubectl delete svc canary-nginx 2>/dev/null

# 7.4.2 블루그린 Rollout
echo "🧹 [7.4.2] 블루그린 Rollout 정리"
kubectl delete rollout bluegreen-nginx 2>/dev/null
kubectl delete svc bluegreen-active bluegreen-preview 2>/dev/null

# 7.4.2 Argo Rollouts 컨트롤러
echo "🧹 [7.4.2] Argo Rollouts 컨트롤러 삭제"
kubectl delete namespace argo-rollouts 2>/dev/null

# 7.4.1 ArgoCD
echo "🧹 [7.4.1] ArgoCD 삭제"
kubectl delete namespace argocd 2>/dev/null

# 7.3.1~7.3.3 OTel 관련 (Jaeger, Collector, Tempo, HotROD)
echo "🧹 [7.3] OTel 관련 리소스 정리"
kubectl delete deploy hotrod 2>/dev/null
kubectl delete svc hotrod 2>/dev/null
kubectl delete deploy jaeger -n monitoring 2>/dev/null
kubectl delete svc jaeger -n monitoring 2>/dev/null
kubectl delete deploy otel-collector -n monitoring 2>/dev/null
kubectl delete svc otel-collector -n monitoring 2>/dev/null
kubectl delete configmap otel-collector-config -n monitoring 2>/dev/null
helm uninstall tempo --namespace monitoring 2>/dev/null

# 7.2.3 Prometheus + Grafana (kube-prometheus-stack)
echo "🧹 [7.2.3] Prometheus + Grafana 삭제"
helm uninstall prometheus-stack --namespace monitoring --no-hooks 2>/dev/null

# 7.2.3 컨트롤 플레인 메트릭 바인딩 복원 (CP 노드에서 실행 필요)
echo "🧹 [7.2.3] 컨트롤 플레인 메트릭 바인딩 복원"
if [ -f /etc/kubernetes/manifests/kube-controller-manager.yaml ]; then
  sed s,"- --bind-address=0.0.0.0","- --bind-address=127.0.0.1",g \
      -i /etc/kubernetes/manifests/kube-controller-manager.yaml
  sed s,"- --bind-address=0.0.0.0","- --bind-address=127.0.0.1",g \
      -i /etc/kubernetes/manifests/kube-scheduler.yaml
  sed s,"- --listen-metrics-urls=http://0.0.0.0:2381","- --listen-metrics-urls=http://127.0.0.1:2381",g \
      -i /etc/kubernetes/manifests/etcd.yaml
  echo "   컨트롤 플레인 메트릭 바인딩 복원 완료 (잠시 대기...)"
  sleep 5
  while [ -z "$(crictl ps | grep etcd | grep Running)" ] 2>/dev/null; do
    echo "   컨트롤 플레인 재시작 중..."
    sleep 3
  done
else
  echo "   ⚠️  CP 노드가 아닙니다. CP 노드에서 cleanup_7.2.3_tasks.sh를 별도로 실행하세요."
fi

# 7.1 대시보드/헤드램프 관련 (이미 정리되었을 수 있음)
echo "🧹 [7.1] 대시보드 관련 정리"
kubectl delete deployment nginx-by-k8s-dash 2>/dev/null
kubectl delete deployment nginx-by-headlamp 2>/dev/null
kubectl delete -f $HOME/_Book_k8sInfra/ch7/7.1.2/kubernetes-dashboard.yaml 2>/dev/null

# monitoring 네임스페이스 정리 (남은 리소스가 있다면)
echo "🧹 monitoring 네임스페이스 남은 리소스 확인"
REMAINING="$(kubectl get all -n monitoring 2>/dev/null | grep -v 'No resources')"
if [ -n "$REMAINING" ]; then
  echo "   남은 리소스:"
  echo "$REMAINING"
  echo "   kubectl delete namespace monitoring 으로 전체 삭제 가능"
else
  kubectl delete namespace monitoring 2>/dev/null
fi

echo ""
echo "=============================================="
echo "✅ 정리 완료. 7.5 sLLM 실습을 시작할 수 있습니다."
echo "=============================================="
echo ""
echo "📋 현재 클러스터 리소스 확인:"
kubectl top nodes 2>/dev/null || kubectl get nodes -o wide
