# 7.4.3 ArgoCD + Rollouts 통합 — GitOps 기반 점진적 배포

## 목표
- Git push → ArgoCD가 변경 감지 → Rollouts가 카나리로 안전하게 배포
- 7.2.3 Grafana에서 배포 중 메트릭 변화를 관찰
- 모니터링(7.2) + 관측(7.3) + 배포(7.4) 전체 파이프라인 통합

## 사전 조건
- 7.4.1 ArgoCD + 7.4.2 Argo Rollouts 설치 완료
- 7.2.3 Prometheus + Grafana 동작 중

## TODO
- [ ] ArgoCD Application으로 Rollout 리소스 관리 설정
- [ ] Git push 트리거 → 카나리 배포 시나리오
- [ ] Grafana 대시보드에서 배포 중 메트릭 관찰 가이드
