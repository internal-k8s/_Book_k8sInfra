# 7.4.3 Argo Rollouts — 카나리(Canary) 배포

## 목표
- 카나리 배포 전략으로 트래픽을 단계적으로 새 버전으로 이동
- 단계별 승격(promote)과 롤백(abort) 실습
- 7.4.2 블루그린과의 차이점 비교

## 사전 조건
- 7.4.2 Argo Rollouts 설치 완료

## 실습 파일
- `canary-rollout.yaml` — 카나리 Rollout + Service (25→50→75→100%)
- `deploy_canary.sh` — 카나리 배포 + 실습 가이드
- `cleanup_7.4.3_tasks.sh` — 리소스 정리

## 실습 순서
1. `deploy_canary.sh`로 카나리 Rollout 배포
2. 이미지 변경으로 카나리 트리거
3. `kubectl argo rollouts get rollout canary-nginx --watch`로 진행 상태 확인
4. `kubectl argo rollouts promote canary-nginx`로 단계별 승격
5. 7.4.2 블루그린과 비교
