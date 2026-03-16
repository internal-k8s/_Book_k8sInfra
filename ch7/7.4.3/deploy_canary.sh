#!/usr/bin/env bash

echo "=============================================="
echo " 7.4.3 카나리(Canary) 배포 실습"
echo "=============================================="
echo ""

echo "🚀 Deploy Canary Rollout."
kubectl apply -f $HOME/_Book_k8sInfra/ch7/7.4.3/canary-rollout.yaml

echo "⏳ Wait for Rollout to be ready..."
sleep 10

CANARY_IP="$(kubectl get svc canary-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
echo ""
echo "✅ Canary Rollout deployed."
echo "   서비스: http://$CANARY_IP"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 카나리 배포 트리거 및 단계별 승격"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1️⃣  이미지를 변경하여 카나리 배포 트리거:"
echo "   kubectl argo rollouts set image canary-nginx nginx=nginx:1.27.3"
echo ""
echo "2️⃣  상태 확인 (25% 트래픽이 새 버전으로):"
echo "   kubectl argo rollouts get rollout canary-nginx --watch"
echo ""
echo "3️⃣  수동 승격 (25% → 50% → 75% → 100%):"
echo "   kubectl argo rollouts promote canary-nginx"
echo ""
echo "4️⃣  문제 발생 시 롤백:"
echo "   kubectl argo rollouts abort canary-nginx"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 카나리 vs 블루그린 비교"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  블루그린: 새 버전을 100% 준비 → 한 번에 전환"
echo "  카나리:   트래픽을 단계적으로 이동 (25→50→75→100%)"
echo "           문제 발견 시 영향 범위가 작음"
